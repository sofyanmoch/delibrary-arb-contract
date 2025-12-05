// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IBookToken {
    function mint(address to, uint256 amount) external;
}

/**
 * @title BookLending
 * @notice Peer-to-peer book lending platform with deposits and token rewards
 * @dev Optimized for Arbitrum - Phase 1: Restricted to Universitas Harkat Negeri pickup points only
 */
contract BookLending is ReentrancyGuard, Ownable {
    IBookToken public bookToken;

    enum BookCondition { Mint, Good, Fair, Damaged }
    enum LoanStatus { Active, Returned, Late, Disputed }

    struct Book {
        uint256 id;
        address lender;
        string title;
        string author;
        string isbn;
        BookCondition condition;
        uint256 depositAmount;
        uint256 duration;
        string pickupPoint;
        bool isAvailable;
        uint256 timesLent;
        uint256 createdAt;
    }

    struct Loan {
        uint256 id;
        uint256 bookId;
        address borrower;
        uint256 depositPaid;
        uint256 startTime;
        uint256 deadline;
        LoanStatus status;
        BookCondition conditionAfterReturn;
        uint256 returnedAt;
    }

    struct UserProfile {
        string username;
        uint256 booksLent;
        uint256 booksBorrowed;
        uint256 totalEarnings;
        bool isRegistered;
    }

    uint256 private _bookIdCounter;
    uint256 private _loanIdCounter;
    
    mapping(uint256 => Book) public books;
    mapping(uint256 => Loan) public loans;
    mapping(address => uint256[]) public userBooks;
    mapping(address => uint256[]) public userLoans;
    mapping(string => uint256) public pickupPointEarnings;
    mapping(string => bool) public allowedPickupPoints;
    mapping(address => UserProfile) public userProfiles;
    mapping(string => address) public usernameToAddress;
    
    address[] private allUsers;

    uint256 public constant LENDER_REWARD = 10 * 10**18;
    uint256 public constant PICKUP_POINT_REWARD = 5 * 10**18;
    uint256 public constant BORROWER_REWARD = 2 * 10**18;
    uint256 public constant LATE_PENALTY_PERCENT = 5;
    uint256 public constant DAMAGE_PENALTY_PERCENT = 50;

    // Phase 1: Only Universitas Harkat Negeri locations
    string public constant PICKUP_POINT_1 = "Universitas Harkat Negeri (Kampus Pendidikan)";
    string public constant PICKUP_POINT_2 = "Universitas Harkat Negeri (Kampus Mataram)";

    event BookListed(uint256 indexed bookId, address indexed lender, string title, uint256 depositAmount, uint256 duration);
    event BookBorrowed(uint256 indexed loanId, uint256 indexed bookId, address indexed borrower, uint256 depositPaid, uint256 deadline);
    event BookReturned(uint256 indexed loanId, uint256 indexed bookId, address indexed borrower, LoanStatus status, uint256 refundAmount);
    event TokensRewarded(address indexed recipient, uint256 amount, string reason);
    event LatePenaltyApplied(uint256 indexed loanId, uint256 penaltyAmount, uint256 daysLate);
    event PickupPointAdded(string pickupPoint);
    event PickupPointRemoved(string pickupPoint);
    event UsernameChanged(address indexed user, string oldUsername, string newUsername);

    constructor(address _bookToken) Ownable(msg.sender) {
        bookToken = IBookToken(_bookToken);
        
        // Initialize Phase 1 pickup points
        allowedPickupPoints[PICKUP_POINT_1] = true;
        allowedPickupPoints[PICKUP_POINT_2] = true;
        
        emit PickupPointAdded(PICKUP_POINT_1);
        emit PickupPointAdded(PICKUP_POINT_2);
    }

    /**
     * @notice Set or change username for the caller
     * @param _username The desired username (3-20 characters, alphanumeric and spaces only)
     */
    function setUsername(string memory _username) external {
        require(bytes(_username).length >= 3 && bytes(_username).length <= 20, "Username must be 3-20 characters");
        require(_isValidUsername(_username), "Username can only contain letters, numbers, and spaces");
        require(usernameToAddress[_username] == address(0) || usernameToAddress[_username] == msg.sender, "Username already taken");
        
        UserProfile storage profile = userProfiles[msg.sender];
        string memory oldUsername = profile.username;
        
        // Remove old username mapping if exists
        if (bytes(oldUsername).length > 0) {
            delete usernameToAddress[oldUsername];
        }
        
        // Set new username
        profile.username = _username;
        usernameToAddress[_username] = msg.sender;
        
        // Register user if first time
        if (!profile.isRegistered) {
            profile.isRegistered = true;
            allUsers.push(msg.sender);
        }
        
        emit UsernameChanged(msg.sender, oldUsername, _username);
    }

    /**
     * @notice Check if username contains only valid characters
     * @param _username The username to validate
     * @return bool True if valid
     */
    function _isValidUsername(string memory _username) private pure returns (bool) {
        bytes memory b = bytes(_username);
        for (uint i = 0; i < b.length; i++) {
            bytes1 char = b[i];
            if (!(
                (char >= 0x30 && char <= 0x39) || // 0-9
                (char >= 0x41 && char <= 0x5A) || // A-Z
                (char >= 0x61 && char <= 0x7A) || // a-z
                char == 0x20                       // space
            )) {
                return false;
            }
        }
        return true;
    }

    /**
     * @notice Get user profile information
     * @param _user The user address
     * @return username The user's display name
     * @return booksLent Total books lent by user
     * @return booksBorrowed Total books borrowed by user
     * @return totalEarnings Total ETH earned from lending
     * @return isRegistered Whether user has set a username
     */
    function getUserProfile(address _user) external view returns (
        string memory username,
        uint256 booksLent,
        uint256 booksBorrowed,
        uint256 totalEarnings,
        bool isRegistered
    ) {
        UserProfile memory profile = userProfiles[_user];
        return (
            profile.username,
            profile.booksLent,
            profile.booksBorrowed,
            profile.totalEarnings,
            profile.isRegistered
        );
    }

    /**
     * @notice Get leaderboard of top lenders
     * @param _limit Maximum number of results to return
     * @return addresses Array of user addresses
     * @return usernames Array of usernames
     * @return booksLent Array of books lent counts
     */
    function getTopLenders(uint256 _limit) external view returns (
        address[] memory addresses,
        string[] memory usernames,
        uint256[] memory booksLent
    ) {
        uint256 userCount = allUsers.length;
        if (userCount == 0) {
            return (new address[](0), new string[](0), new uint256[](0));
        }
        
        uint256 limit = _limit > userCount ? userCount : _limit;
        
        // Create arrays to hold sorted data
        address[] memory sortedAddresses = new address[](userCount);
        uint256[] memory sortedCounts = new uint256[](userCount);
        
        // Copy data
        for (uint256 i = 0; i < userCount; i++) {
            sortedAddresses[i] = allUsers[i];
            sortedCounts[i] = userProfiles[allUsers[i]].booksLent;
        }
        
        // Simple bubble sort (descending)
        for (uint256 i = 0; i < userCount - 1; i++) {
            for (uint256 j = 0; j < userCount - i - 1; j++) {
                if (sortedCounts[j] < sortedCounts[j + 1]) {
                    // Swap counts
                    uint256 tempCount = sortedCounts[j];
                    sortedCounts[j] = sortedCounts[j + 1];
                    sortedCounts[j + 1] = tempCount;
                    
                    // Swap addresses
                    address tempAddr = sortedAddresses[j];
                    sortedAddresses[j] = sortedAddresses[j + 1];
                    sortedAddresses[j + 1] = tempAddr;
                }
            }
        }
        
        // Prepare result arrays
        addresses = new address[](limit);
        usernames = new string[](limit);
        booksLent = new uint256[](limit);
        
        for (uint256 i = 0; i < limit; i++) {
            addresses[i] = sortedAddresses[i];
            usernames[i] = userProfiles[sortedAddresses[i]].username;
            booksLent[i] = sortedCounts[i];
        }
        
        return (addresses, usernames, booksLent);
    }

    /**
     * @notice Get leaderboard of top borrowers
     * @param _limit Maximum number of results to return
     * @return addresses Array of user addresses
     * @return usernames Array of usernames
     * @return booksBorrowed Array of books borrowed counts
     */
    function getTopBorrowers(uint256 _limit) external view returns (
        address[] memory addresses,
        string[] memory usernames,
        uint256[] memory booksBorrowed
    ) {
        uint256 userCount = allUsers.length;
        if (userCount == 0) {
            return (new address[](0), new string[](0), new uint256[](0));
        }
        
        uint256 limit = _limit > userCount ? userCount : _limit;
        
        // Create arrays to hold sorted data
        address[] memory sortedAddresses = new address[](userCount);
        uint256[] memory sortedCounts = new uint256[](userCount);
        
        // Copy data
        for (uint256 i = 0; i < userCount; i++) {
            sortedAddresses[i] = allUsers[i];
            sortedCounts[i] = userProfiles[allUsers[i]].booksBorrowed;
        }
        
        // Simple bubble sort (descending)
        for (uint256 i = 0; i < userCount - 1; i++) {
            for (uint256 j = 0; j < userCount - i - 1; j++) {
                if (sortedCounts[j] < sortedCounts[j + 1]) {
                    // Swap counts
                    uint256 tempCount = sortedCounts[j];
                    sortedCounts[j] = sortedCounts[j + 1];
                    sortedCounts[j + 1] = tempCount;
                    
                    // Swap addresses
                    address tempAddr = sortedAddresses[j];
                    sortedAddresses[j] = sortedAddresses[j + 1];
                    sortedAddresses[j + 1] = tempAddr;
                }
            }
        }
        
        // Prepare result arrays
        addresses = new address[](limit);
        usernames = new string[](limit);
        booksBorrowed = new uint256[](limit);
        
        for (uint256 i = 0; i < limit; i++) {
            addresses[i] = sortedAddresses[i];
            usernames[i] = userProfiles[sortedAddresses[i]].username;
            booksBorrowed[i] = sortedCounts[i];
        }
        
        return (addresses, usernames, booksBorrowed);
    }

    /**
     * @notice Check if a pickup point is allowed
     * @param _pickupPoint The pickup point name to check
     * @return bool True if the pickup point is allowed
     */
    function isPickupPointAllowed(string memory _pickupPoint) public view returns (bool) {
        return allowedPickupPoints[_pickupPoint];
    }

    /**
     * @notice Owner can add new pickup points for future phases
     * @param _pickupPoint The pickup point name to add
     */
    function addPickupPoint(string memory _pickupPoint) external onlyOwner {
        require(bytes(_pickupPoint).length > 0, "Pickup point name required");
        require(!allowedPickupPoints[_pickupPoint], "Pickup point already exists");
        
        allowedPickupPoints[_pickupPoint] = true;
        emit PickupPointAdded(_pickupPoint);
    }

    /**
     * @notice Owner can remove pickup points
     * @param _pickupPoint The pickup point name to remove
     */
    function removePickupPoint(string memory _pickupPoint) external onlyOwner {
        require(allowedPickupPoints[_pickupPoint], "Pickup point does not exist");
        
        allowedPickupPoints[_pickupPoint] = false;
        emit PickupPointRemoved(_pickupPoint);
    }

    function listBook(
        string memory _title,
        string memory _author,
        string memory _isbn,
        BookCondition _condition,
        uint256 _depositAmount,
        uint256 _duration,
        string memory _pickupPoint
    ) external returns (uint256) {
        require(bytes(_title).length > 0, "Title required");
        require(bytes(_pickupPoint).length > 0, "Pickup point required");
        require(allowedPickupPoints[_pickupPoint], "Invalid pickup point - must be Universitas Harkat Negeri location");
        require(_depositAmount > 0, "Deposit must be > 0");
        require(_duration >= 1 days && _duration <= 90 days, "Invalid duration");

        _bookIdCounter++;
        uint256 newBookId = _bookIdCounter;

        books[newBookId] = Book({
            id: newBookId,
            lender: msg.sender,
            title: _title,
            author: _author,
            isbn: _isbn,
            condition: _condition,
            depositAmount: _depositAmount,
            duration: _duration,
            pickupPoint: _pickupPoint,
            isAvailable: true,
            timesLent: 0,
            createdAt: block.timestamp
        });

        userBooks[msg.sender].push(newBookId);
        emit BookListed(newBookId, msg.sender, _title, _depositAmount, _duration);
        return newBookId;
    }

    function borrowBook(uint256 _bookId) external payable nonReentrant returns (uint256) {
        Book storage book = books[_bookId];
        
        require(book.id != 0, "Book does not exist");
        require(book.isAvailable, "Book not available");
        require(book.lender != msg.sender, "Cannot borrow own book");
        require(msg.value >= book.depositAmount, "Insufficient deposit");

        book.isAvailable = false;
        book.timesLent++;

        // Update borrower profile
        UserProfile storage borrowerProfile = userProfiles[msg.sender];
        borrowerProfile.booksBorrowed++;
        if (!borrowerProfile.isRegistered) {
            borrowerProfile.isRegistered = true;
            allUsers.push(msg.sender);
        }

        _loanIdCounter++;
        uint256 newLoanId = _loanIdCounter;
        uint256 deadline = block.timestamp + book.duration;

        loans[newLoanId] = Loan({
            id: newLoanId,
            bookId: _bookId,
            borrower: msg.sender,
            depositPaid: msg.value,
            startTime: block.timestamp,
            deadline: deadline,
            status: LoanStatus.Active,
            conditionAfterReturn: BookCondition.Mint,
            returnedAt: 0
        });

        userLoans[msg.sender].push(newLoanId);

        if (msg.value > book.depositAmount) {
            payable(msg.sender).transfer(msg.value - book.depositAmount);
        }

        emit BookBorrowed(newLoanId, _bookId, msg.sender, book.depositAmount, deadline);
        return newLoanId;
    }

    function returnBook(uint256 _loanId, BookCondition _conditionAfter) external nonReentrant {
        Loan storage loan = loans[_loanId];
        Book storage book = books[loan.bookId];

        require(loan.id != 0, "Loan does not exist");
        require(loan.borrower == msg.sender, "Not the borrower");
        require(loan.status == LoanStatus.Active, "Loan not active");

        loan.conditionAfterReturn = _conditionAfter;
        loan.returnedAt = block.timestamp;

        uint256 refundAmount = loan.depositPaid;
        uint256 penaltyAmount = 0;
        uint256 lenderEarnings = 0;

        bool isLate = block.timestamp > loan.deadline;
        if (isLate) {
            uint256 daysLate = (block.timestamp - loan.deadline) / 1 days + 1;
            penaltyAmount = (loan.depositPaid * LATE_PENALTY_PERCENT * daysLate) / 100;
            
            if (penaltyAmount > loan.depositPaid) {
                penaltyAmount = loan.depositPaid;
            }

            refundAmount -= penaltyAmount;
            lenderEarnings += penaltyAmount;
            loan.status = LoanStatus.Late;
            payable(book.lender).transfer(penaltyAmount);
            emit LatePenaltyApplied(_loanId, penaltyAmount, daysLate);
        } else {
            loan.status = LoanStatus.Returned;
        }

        if (_conditionAfter == BookCondition.Damaged) {
            uint256 damageAmount = (loan.depositPaid * DAMAGE_PENALTY_PERCENT) / 100;
            refundAmount -= damageAmount;
            uint256 damageEarnings = (damageAmount * 60) / 100;
            lenderEarnings += damageEarnings;
            payable(book.lender).transfer(damageEarnings);
        }

        // Update lender profile with earnings
        UserProfile storage lenderProfile = userProfiles[book.lender];
        lenderProfile.booksLent++;
        lenderProfile.totalEarnings += lenderEarnings;
        if (!lenderProfile.isRegistered) {
            lenderProfile.isRegistered = true;
            allUsers.push(book.lender);
        }

        if (refundAmount > 0) {
            if (refundAmount > 0) {
                (bool refundSuccess, ) = payable(msg.sender).call{value: refundAmount}("");
                require(refundSuccess, "Refund failed");
            }
        }

        book.isAvailable = true;
        _rewardParticipants(book.lender, msg.sender, book.pickupPoint, isLate);
        emit BookReturned(_loanId, loan.bookId, msg.sender, loan.status, refundAmount);
    }

    function _rewardParticipants(address _lender, address _borrower, string memory _pickupPoint, bool _isLate) internal {
        bookToken.mint(_lender, LENDER_REWARD);
        emit TokensRewarded(_lender, LENDER_REWARD, "Lender reward");

        if (!_isLate) {
            bookToken.mint(_borrower, BORROWER_REWARD);
            emit TokensRewarded(_borrower, BORROWER_REWARD, "Borrower reward");
        }

        pickupPointEarnings[_pickupPoint] += PICKUP_POINT_REWARD;
        emit TokensRewarded(address(this), PICKUP_POINT_REWARD, string(abi.encodePacked("Pickup: ", _pickupPoint)));
    }

    function handleLateReturn(uint256 _loanId) external nonReentrant {
        Loan storage loan = loans[_loanId];
        Book storage book = books[loan.bookId];

        require(loan.id != 0, "Loan does not exist");
        require(loan.status == LoanStatus.Active, "Loan not active");
        require(block.timestamp > loan.deadline, "Not late yet");

        uint256 daysLate = (block.timestamp - loan.deadline) / 1 days + 1;
        uint256 penaltyAmount = (loan.depositPaid * LATE_PENALTY_PERCENT * daysLate) / 100;

        if (penaltyAmount > loan.depositPaid) {
            penaltyAmount = loan.depositPaid;
        }

        payable(book.lender).transfer(penaltyAmount);
        emit LatePenaltyApplied(_loanId, penaltyAmount, daysLate);
    }

    function getUserBooks(address _user) external view returns (uint256[] memory) {
        return userBooks[_user];
    }

    function getUserLoans(address _user) external view returns (uint256[] memory) {
        return userLoans[_user];
    }

    function getBook(uint256 _bookId) external view returns (
        uint256 id, address lender, string memory title, string memory author,
        string memory isbn, BookCondition condition, uint256 depositAmount,
        uint256 duration, string memory pickupPoint, bool isAvailable, uint256 timesLent
    ) {
        Book memory book = books[_bookId];
        return (book.id, book.lender, book.title, book.author, book.isbn,
                book.condition, book.depositAmount, book.duration,
                book.pickupPoint, book.isAvailable, book.timesLent);
    }

    function getLoan(uint256 _loanId) external view returns (
        uint256 id, uint256 bookId, address borrower, uint256 depositPaid,
        uint256 startTime, uint256 deadline, LoanStatus status, uint256 returnedAt
    ) {
        Loan memory loan = loans[_loanId];
        return (loan.id, loan.bookId, loan.borrower, loan.depositPaid,
                loan.startTime, loan.deadline, loan.status, loan.returnedAt);
    }

    function getTotalBooks() external view returns (uint256) {
        return _bookIdCounter;
    }

    function getTotalLoans() external view returns (uint256) {
        return _loanIdCounter;
    }

    function emergencyWithdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    receive() external payable {}
}