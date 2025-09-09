param(
    $sink,
    $folder1,
    $folder2,
    [switch]$Help,
    [switch]$Usage
)

function Compare-Folders-Usage {
    Write-Host ""
    Write-Host "###########################################################################" -ForegroundColor Cyan
    Write-Host "#                     Compare-Folders - Usage Guide                       #" -ForegroundColor Cyan
    Write-Host "###########################################################################" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "DESCRIPTION:" -ForegroundColor Yellow
    Write-Host "  Compares the contents of two folders, including subfolders."
    Write-Host "  Logs differences in file and folder counts, as well as missing items."
    Write-Host ""
    Write-Host "PARAMETERS:" -ForegroundColor Yellow
    Write-Host "  -folder1            Path to the first folder to compare."
    Write-Host "  -folder2            Path to the second folder to compare."
    Write-Host ""
    Write-Host "OUTPUT FILES:" -ForegroundColor Yellow
    Write-Host "  Compare-Folders-Stats-Log.txt   Summary of file and folder counts."
    Write-Host "  Compare-Folders-File-Log.txt    Details of missing files and folders."
    Write-Host ""
    Write-Host "USAGE EXAMPLE:" -ForegroundColor Yellow
    Write-Host "  Compare-Folders -folder1 'C:\Path\To\FolderA' -folder2 'C:\Path\To\FolderB'"
    Write-Host ""
}

function Compare-Folders {
    param (
        [string]$folder1,
        [string]$folder2
    )

    # Compare the files in the root of both folders
    $folder1Files = Get-ChildItem -Path $folder1 -File
    $folder2Files = Get-ChildItem -Path $folder2 -File | ForEach-Object { [string]$_.Name } # Convert to just names for easier comparison
    $folder1FilesCount = $folder1Files.Count
    $folder2FilesCount = $folder2Files.Count
    Write-Output "Files in $folder1 - $folder1FilesCount | Files in $folder2 - $folder2FilesCount | $(if($folder1FilesCount -eq $folder2FilesCount) { "Match  | 0 " } else { "MisMatch | $($folder1FilesCount - $folder2FilesCount)" })" | Out-File -FilePath ".\Compare-Folders-Stats-Log.txt" -Append
    $folder2FilesList = [System.Collections.Generic.List[string]]::new()
    $folder2Files | ForEach-Object { $folder2FilesList.Add($_) }
    # $folder2FilesList.AddRange( $folder2Files )
    foreach ($file in $folder1Files) {
        $fileName = $file.Name
        $filePathInFolder2 = Join-Path -Path $folder2 -ChildPath $fileName
        if (Test-Path -Path $filePathInFolder2) {
            Write-Output "File '$fileName' exists in both folders." | Out-File -FilePath ".\Compare-Folders-File-Log.txt" -Append
            $folder2FilesList.Remove($fileName) | Out-Null
        }
        else {
            Write-Output "File '$fileName' is missing in folder2." | Out-File -FilePath ".\Compare-Folders-File-Log.txt" -Append
        }
    }
    foreach ($file in $folder2FilesList) {
        Write-Output "File '$($file.Name)' is missing in folder1." | Out-File -FilePath ".\Compare-Folders-File-Log.txt" -Append
    }
    # Now compare subfolders
    $folder1SubFolders = Get-ChildItem -Path $folder1 -Directory
    $folder2SubFolders = Get-ChildItem -Path $folder2 -Directory | ForEach-Object { [string]$_.Name } # Convert to just names for easier comparison

    $folder1SubFoldersCount = $folder1SubFolders.Count
    $folder2SubFoldersCount = $folder2SubFolders.Count

    Write-Output "Folders in $folder1 - $folder1SubFoldersCount | Files in $folder2 - $folder2SubFoldersCount | $(if($folder1SubFoldersCount -eq $folder2SubFoldersCount) { "Match  | 0 " } else { "MisMatch | $($folder1SubFoldersCount - $folder2SubFoldersCount)" })" | Out-File -FilePath ".\Compare-Folders-Stats-Log.txt" -Append
    $folder2SubFoldersList = [System.Collections.Generic.List[string]]::new()
    $folder2SubFolders | ForEach-Object { $folder2SubFoldersList.Add($_) }

    foreach ($subFolder1 in $folder1SubFolders) {
        $subFolder2 = Join-Path -Path $folder2 -ChildPath $subFolder1.Name
        if (Test-Path -Path $subFolder2 -PathType Container) {
            $folder2SubFoldersList.Remove($subFolder1.Name) | Out-Null
            Compare-Folders -folder1 $subFolder1.FullName -folder2 $subFolder2
        }
        else {
            Write-Output "Subfolder '$($subFolder1.Name)' is missing in folder2." | Out-File -FilePath ".\Compare-Folders-File-Log.txt" -Append
        }
    }
    foreach ($subFolder in $folder2SubFoldersList) {
        Write-Output "Subfolder '$subFolder' is missing in folder1." | Out-File -FilePath ".\Compare-Folders-File-Log.txt" -Append
    }
}
if (($null -eq $sink) -or ($sink -in @('/?', '/h', '/help', '--help')) -or $Usage -or $Help) {
    Compare-Folders-Usage
    exit 0
}


if (($null -eq $folder1) -or ($null -eq $folder2)) {
    Write-Host "Error: Both -folder1 and -folder2 parameters are required." -ForegroundColor Red
    exit 1
}
if (-not (Test-Path -Path $folder1 -PathType Container)) {
    Write-Host "Error: Folder1 path '$folder1' does not exist or is not a directory." -ForegroundColor Red
    exit 1
}
if (-not (Test-Path -Path $folder2 -PathType Container)) {
    Write-Host "Error: Folder2 path '$folder2' does not exist or is not a directory." -ForegroundColor Red
    exit 1
}

#Compare-Folders -folder1 $folder1 -folder2 $folder2