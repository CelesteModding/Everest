$S3Key=$args[0]
$S3Secret=$args[1]

Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -Path "azure-pipelines-ext.cs" -ReferencedAssemblies "System.IO.Compression.FileSystem"

$BuildNumber = [string]([int]$env:Build_BuildId + [int]$env:Build_BuildIdOffset)
$Suffix = "-$env:Build_SourceBranchName"

if ($Suffix -eq "-master") {
	$Suffix = ""
}

$ZIP="build-$BuildNumber$Suffix.zip"

echo "Creating .zip"
[EverestPS]::Zip($env:Build_ArtifactStagingDirectory, $ZIP)

echo "Pushing .zip to S3"
[EverestPS]::PutS3($S3Key, $S3Secret, ".", $ZIP, "/everest-travis/", "application/x-compressed-zip")

echo "Getting latest builds_index.txt"
[EverestPS]::Get("https://lollyde.ams3.digitaloceanspaces.com/everest-travis/builds_index.txt", "builds_index.txt")

echo "Updating builds_index.txt"
Add-Content builds_index.txt "/lollyde/everest-travis/$ZIP $ZIP`n"

echo "Pushing builds_index.txt to S3"
[EverestPS]::PutS3($S3Key, $S3Secret, ".", "builds_index.txt", "/everest-travis/", "text/plain")

echo "Generating new index.html"
[EverestPS]::RebuildHTML("builds_index.txt", "index.html")

echo "Pushing index.html to S3"
[EverestPS]::PutS3($S3Key, $S3Secret, ".", "index.html", "/", "text/html")
