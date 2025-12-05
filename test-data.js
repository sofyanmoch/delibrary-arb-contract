// Run this script from Truffle console with: exec test-data.js

const BookLending = artifacts.require("BookLending");
const BookToken = artifacts.require("BookToken");

module.exports = async function(callback) {
  try {
    console.log("\n🚀 Adding test data to BookLending contract...\n");

    const bookLending = await BookLending.deployed();
    const bookToken = await BookToken.deployed();
    const accounts = await web3.eth.getAccounts();

    console.log("📍 Contract Address:", bookLending.address);
    console.log("👥 Using accounts:", accounts.slice(0, 5));
    console.log("");

    // Set usernames
    console.log("👤 Setting usernames...");
    await bookLending.setUsername("Alice", {from: accounts[0]});
    await bookLending.setUsername("Bob", {from: accounts[1]});
    await bookLending.setUsername("Charlie", {from: accounts[2]});
    await bookLending.setUsername("Diana", {from: accounts[3]});
    await bookLending.setUsername("Eve", {from: accounts[4]});
    console.log("✅ Usernames set\n");

    // List books
    console.log("📚 Listing books...");

    // Alice lists 3 books
    await bookLending.listBook(
      "The Great Gatsby",
      "F. Scott Fitzgerald",
      "9780743273565",
      0, // Mint
      web3.utils.toWei("0.1", "ether"),
      7 * 24 * 60 * 60,
      "Universitas Harkat Negeri (Kampus Pendidikan)",
      {from: accounts[0]}
    );
    console.log("  ✓ Alice: The Great Gatsby");

    await bookLending.listBook(
      "To Kill a Mockingbird",
      "Harper Lee",
      "9780061120084",
      1, // Good
      web3.utils.toWei("0.08", "ether"),
      5 * 24 * 60 * 60,
      "Universitas Harkat Negeri (Kampus Pendidikan)",
      {from: accounts[0]}
    );
    console.log("  ✓ Alice: To Kill a Mockingbird");

    await bookLending.listBook(
      "Pride and Prejudice",
      "Jane Austen",
      "9780141439518",
      0, // Mint
      web3.utils.toWei("0.12", "ether"),
      10 * 24 * 60 * 60,
      "Universitas Harkat Negeri (Kampus Mataram)",
      {from: accounts[0]}
    );
    console.log("  ✓ Alice: Pride and Prejudice");

    // Bob lists 2 books
    await bookLending.listBook(
      "1984",
      "George Orwell",
      "9780451524935",
      0, // Mint
      web3.utils.toWei("0.15", "ether"),
      14 * 24 * 60 * 60,
      "Universitas Harkat Negeri (Kampus Mataram)",
      {from: accounts[1]}
    );
    console.log("  ✓ Bob: 1984");

    await bookLending.listBook(
      "The Catcher in the Rye",
      "J.D. Salinger",
      "9780316769174",
      1, // Good
      web3.utils.toWei("0.09", "ether"),
      7 * 24 * 60 * 60,
      "Universitas Harkat Negeri (Kampus Pendidikan)",
      {from: accounts[1]}
    );
    console.log("  ✓ Bob: The Catcher in the Rye");

    // Diana lists 1 book
    await bookLending.listBook(
      "Harry Potter and the Sorcerer's Stone",
      "J.K. Rowling",
      "9780439708180",
      0, // Mint
      web3.utils.toWei("0.2", "ether"),
      21 * 24 * 60 * 60,
      "Universitas Harkat Negeri (Kampus Pendidikan)",
      {from: accounts[3]}
    );
    console.log("  ✓ Diana: Harry Potter\n");

    // Create some loans
    console.log("🔄 Creating loans...");

    // Charlie borrows from Alice (book #1)
    await bookLending.borrowBook(1, {
      from: accounts[2],
      value: web3.utils.toWei("0.1", "ether")
    });
    console.log("  ✓ Charlie borrowed 'The Great Gatsby' from Alice");

    // Eve borrows from Bob (book #4)
    await bookLending.borrowBook(4, {
      from: accounts[4],
      value: web3.utils.toWei("0.15", "ether")
    });
    console.log("  ✓ Eve borrowed '1984' from Bob\n");

    // Display statistics
    console.log("📊 Current Statistics:");
    const totalBooks = await bookLending.getTotalBooks();
    const totalLoans = await bookLending.getTotalLoans();
    console.log("  Total Books:", totalBooks.toString());
    console.log("  Total Loans:", totalLoans.toString());
    console.log("");

    // Display leaderboard
    console.log("🏆 Leaderboard (Top Lenders):");
    const leaderboard = await bookLending.getTopLenders(10);
    for(let i = 0; i < leaderboard.addresses.length; i++) {
      if(leaderboard.usernames[i]) {
        console.log(`  ${i+1}. ${leaderboard.usernames[i].padEnd(10)} - ${leaderboard.booksLent[i]} books lent`);
      }
    }
    console.log("");

    // Display top borrowers
    console.log("📖 Top Borrowers:");
    const borrowers = await bookLending.getTopBorrowers(10);
    for(let i = 0; i < borrowers.addresses.length; i++) {
      if(borrowers.usernames[i]) {
        console.log(`  ${i+1}. ${borrowers.usernames[i].padEnd(10)} - ${borrowers.booksBorrowed[i]} books borrowed`);
      }
    }
    console.log("");

    console.log("✅ Test data added successfully!");
    console.log("");
    console.log("🧪 Test the API with:");
    console.log("  curl http://localhost:3000/api/booklending/total-books");
    console.log("  curl http://localhost:3000/api/booklending/leaderboard?limit=10");
    console.log("");

    callback();
  } catch (error) {
    console.error("❌ Error:", error);
    callback(error);
  }
};
