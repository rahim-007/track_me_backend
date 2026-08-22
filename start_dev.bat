@echo off
REM ============================================================
REM  Track Me - one-click local dev launcher
REM  Starts portable PostgreSQL + NestJS backend + prints the
REM  exact flutter run command for the Android emulator.
REM ============================================================
setlocal
set PGHOME=%LOCALAPPDATA%\trackme-pg
set PGBIN=%PGHOME%\postgresql-17.2.0-x86_64-pc-windows-msvc\bin
set PGDATA=%PGHOME%\data
set REPO=%~dp0

echo [1/3] Starting PostgreSQL...
"%PGBIN%\pg_ctl.exe" -D "%PGDATA%" -l "%PGHOME%\pg.log" status >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    "%PGBIN%\pg_ctl.exe" -D "%PGDATA%" -l "%PGHOME%\pg.log" start
    timeout /t 3 /nobreak >nul
) else (
    echo       already running.
)

echo [2/3] Starting backend on http://localhost:3000/api ...
start "TrackMe Backend" cmd /k "cd /d "%REPO%track_me_backend" && npx nest start"

echo [3/3] Waiting for backend to come up...
set /a tries=0
:waitloop
timeout /t 2 /nobreak >nul
curl -s -o nul -w "%%{http_code}" http://localhost:3000/api/docs | findstr "200" >nul
if %ERRORLEVEL% EQU 0 goto ready
set /a tries+=1
if %tries% LSS 30 goto waitloop
echo WARNING: backend did not respond within 60s. Check the TrackMe Backend window.
goto done

:ready
echo.
echo ============================================================
echo   Backend is UP:  http://localhost:3000/api/docs
echo   Test login:     rahim@test.com / Test1234!
echo.
echo   Now run the app (pick ONE):
echo     Android emulator : flutter run --dart-define=BASE_URL=http://10.0.2.2:3000/api
echo     Windows desktop  : flutter run --dart-define=BASE_URL=http://localhost:3000/api
echo     Physical phone   : flutter run --dart-define=BASE_URL=http://^<your-pc-ip^>:3000/api
echo ============================================================
goto end

:done
echo Backend failed to start. See the TrackMe Backend window for errors.

:end
endlocal
