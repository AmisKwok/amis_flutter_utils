@echo off

echo Syncing dev branch to master branch and pushing to all remote repositories...
echo.

REM 1. Switch to dev branch and pull latest code
echo 1. Switching to dev branch and pulling latest code...
git checkout dev
if errorlevel 1 (
    echo Failed to switch to dev branch!
    pause
    exit /b 1
)

git pull origin dev
git pull github dev
if errorlevel 1 (
    echo Failed to pull dev branch code!
    pause
    exit /b 1
)
echo dev branch updated successfully!
echo.

REM 2. Switch to master branch
echo 2. Switching to master branch...
git checkout master
if errorlevel 1 (
    echo Failed to switch to master branch!
    pause
    exit /b 1
)
echo Switched to master branch successfully!
echo.

REM 3. Merge dev branch to master branch
echo 3. Merging dev branch to master branch...
git merge dev
if errorlevel 1 (
    echo Failed to merge dev branch to master branch!
    echo Please resolve conflicts manually and try again.
    pause
    exit /b 1
)
echo dev branch merged to master branch successfully!
echo.

REM 4. Push master branch to Gitee
echo 4. Pushing master branch to Gitee...
git push origin master
if errorlevel 1 (
    echo Failed to push master branch to Gitee!
    pause
    exit /b 1
)
echo Pushed master branch to Gitee successfully!
echo.

REM 5. Push master branch to GitHub
echo 5. Pushing master branch to GitHub...
git push github master
if errorlevel 1 (
    echo Failed to push master branch to GitHub!
    pause
    exit /b 1
)
echo Pushed master branch to GitHub successfully!
echo.

REM 6. Switch back to dev branch
echo 6. Switching back to dev branch...
git checkout dev
if errorlevel 1 (
    echo Failed to switch back to dev branch!
    pause
    exit /b 1
)
echo Switched back to dev branch successfully!
echo.

echo Sync completed! dev branch has been successfully merged to master branch and pushed to all remote repositories.
pause