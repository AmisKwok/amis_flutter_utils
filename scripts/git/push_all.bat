@echo off

echo Pushing to all remote repositories...
echo.

echo 1. Pushing to Gitee...
git push origin
if errorlevel 1 (
    echo Gitee push failed!
    pause
    exit /b 1
)
echo Gitee push successful!
echo.

echo 2. Pushing to GitHub...
git push github
if errorlevel 1 (
    echo GitHub push failed!
    pause
    exit /b 1
)
echo GitHub push successful!
echo.

echo All repositories pushed successfully!
pause