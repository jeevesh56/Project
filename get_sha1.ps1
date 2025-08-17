# PowerShell script to get SHA-1 fingerprint for Google Sign-In
# Run this script in your project directory

Write-Host "Getting SHA-1 fingerprint for Google Sign-In..." -ForegroundColor Green

# Check if keytool is available
try {
    $keytoolOutput = & keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android 2>$null
    
    if ($keytoolOutput) {
        $sha1Line = $keytoolOutput | Select-String "SHA1:"
        if ($sha1Line) {
            $sha1 = $sha1Line -replace "SHA1: ", ""
            Write-Host "SHA-1 Fingerprint:" -ForegroundColor Yellow
            Write-Host $sha1 -ForegroundColor Cyan
            Write-Host ""
            Write-Host "Add this SHA-1 to your Firebase project:" -ForegroundColor Green
            Write-Host "1. Go to Firebase Console" -ForegroundColor White
            Write-Host "2. Select your project" -ForegroundColor White
            Write-Host "3. Go to Project Settings" -ForegroundColor White
            Write-Host "4. Add fingerprint to Android app" -ForegroundColor White
            Write-Host "5. Download updated google-services.json" -ForegroundColor White
        } else {
            Write-Host "SHA-1 not found in keytool output" -ForegroundColor Red
        }
    } else {
        Write-Host "Failed to get SHA-1 fingerprint" -ForegroundColor Red
    }
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Make sure you have Java JDK installed and keytool is in your PATH" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")







