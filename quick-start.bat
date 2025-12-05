@echo off
REM BookLending Quick Start Script for Windows
REM This script automates the entire local deployment process

echo =========================================
echo BookLending Quick Start
echo =========================================
echo.

REM Check if Node.js is installed
where node >nul 2>nul
if %errorlevel% neq 0 (
    echo Error: Node.js is not installed
    echo Please install Node.js from https://nodejs.org/
    exit /b 1
)
echo [OK] Node.js is installed

REM Check if Ganache is installed
where ganache >nul 2>nul
if %errorlevel% neq 0 (
    echo Error: Ganache is not installed
    echo.
    echo Please install Ganache CLI:
    echo   npm install -g ganache
    echo.
    echo Or download Ganache GUI from:
    echo   https://trufflesuite.com/ganache/
    exit /b 1
)
echo [OK] Ganache is installed
echo.

REM Install dependencies if needed
echo Step 1: Installing dependencies...
if not exist "node_modules" (
    echo Installing npm packages...
    call npm install
    echo [OK] Dependencies installed
) else (
    echo [OK] Dependencies already installed
)
echo.

REM Clean previous build
echo Step 2: Cleaning previous build...
if exist "build" (
    rmdir /s /q build
    echo [OK] Previous build cleaned
) else (
    echo [INFO] No previous build found
)
echo.

REM Start Ganache in a new window
echo Step 3: Starting Ganache...
start "Ganache" ganache --port 8545 --networkId 5777 --deterministic
timeout /t 5 /nobreak >nul
echo [OK] Ganache started on port 8545
echo.

REM Compile contracts
echo Step 4: Compiling contracts...
call npx truffle compile
if %errorlevel% neq 0 (
    echo [ERROR] Contract compilation failed
    exit /b 1
)
echo [OK] Contracts compiled successfully
echo.

REM Deploy contracts
echo Step 5: Deploying contracts to localhost...
call npx truffle migrate --network development --reset
if %errorlevel% neq 0 (
    echo [ERROR] Contract deployment failed
    exit /b 1
)
echo [OK] Contracts deployed successfully
echo.

REM Display deployment information
echo =========================================
echo Deployment Complete!
echo =========================================
echo.

if exist "deployment-info.json" (
    echo [OK] Deployment information saved to deployment-info.json
    echo.
    type deployment-info.json
    echo.
    echo Next Steps:
    echo -----------
    echo 1. Configure the backend:
    echo    cd ..\backend
    echo    copy .env.example .env
    echo.
    echo 2. Edit backend\.env and add your contract address
    echo.
    echo 3. Start the backend server:
    echo    cd ..\backend
    echo    npm install
    echo    npm start
    echo.
)

echo =========================================
echo Ganache Information:
echo =========================================
echo Network ID:  5777
echo Port:        8545
echo Host:        127.0.0.1
echo Accounts:    10 (each with 100 ETH)
echo.
echo [SUCCESS] All done! Your local blockchain is ready.
echo.
pause
