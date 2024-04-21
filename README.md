# Find Photo Duplicates by Timestamp

This script sorts photo files based on their [Exif creation timestamps](#what-are-exif-creation-timestamps) and identifies duplicates.

> [!WARNING]
> The script uses the Exif metadata field `CreateDate`. Since this field stores the creation time in seconds, the script groups photos as candidates for duplicates that were taken within a few milliseconds of each other. Therefore, photos from exposure series, for example, can also appear in duplicate groups. Please check the photos before deleting them.

Features:

- Sorts photo files by their [Exif creation timestamps](#what-are-exif-creation-timestamps) and logs the results.
- Identifies and logs duplicate photos that share the same timestamp.
- Allows specification of source directories, file extensions, and directories to exclude from the search.
- Provides parallel processing to handle large collections efficiently.
- Does not delete files automatically; you review the candidates for deletion.

## Requirements

- Familiarity with shell usage on Linux or macOS.
- `exiftool` must be installed on your system.

## Installation

1. Download the script.
2. Make the script executable: `chmod +x photo-date-dup-finder.sh`.

> [!TIP]
> Run the script in its own folder to keep your folder structure clean.

## Usage

### Identify files with the same timestamp

1. Open the shell.
2. Navigate to the directory containing the script.
3. Run the script with the necessary parameters:
   ```bash
   ./photo-date-dup-finder.sh -s <SourceDirectoryPath> [-e <ExcludeDirectories>] [-f <FileExtensions>]
   ```

   - `<SourceDirectoryPath>`: The path to the directory containing the photos.
   - `<ExcludeDirectories>`: Comma-separated list of directories to exclude from the search.
   - `<FileExtensions>`: Comma-separated list of file extensions to include (e.g., `cr2,arw,jpg`).

**Results:**

| File                | Description                                        |
| ------------------- | -------------------------------------------------- |
| `found.txt`         | Logs phoots with their [Exif creation timestamps](#what-are-exif-creation-timestamps).                 |
| `rest.txt`          | Lists files that are not photos.                   |
| `remove_pairs.sh`   | Script containing commands to remove duplicates.   |

> [!NOTE]
> These files are overwritten each time the script is run.

### Reviewing Results

1. Inspect `remove_pairs.sh` and decide which photo you want to delete.
3. Execute `./remove_pairs.sh` to delete the photos.

### Clean up

After processing, you may want to organize your photos or delete unnecessary files manually based on the output logs.

## FAQ

### What are Exif creation timestamps?

The Exif creation timestamp is metadata. The Exif metadata is stored in photos and contains information such as the date of capture, camera settings, and possibly location. This script uses the capture date from the Exif data to identify the photos. This script uses the field `CreateDate`. The timestamp in the field is stored in seconds. Therefore, the script groups photos that are shot milliseconds apart. This might be the case if you shoot exposure series.

See also: [Exif (Wikipedia)](https://en.wikipedia.org/wiki/Exif)

### How do I install `exiftool`?

On most Linux distributions, you can install `exiftool` via your package manager. On macOS, you can install `exiftool` with [Homebrew](https://brew.sh/): `brew install exiftool`.

### Can I run the script on a Windows system?

Yes, but you need to install the [Windows Subsystem for Linux](https://learn.microsoft.com/en-us/windows/wsl/about) and install `exiftool` within that subsystem.

### What are the prerequisites for this script to run correctly?

You need `exiftool` installed, and the script should have permissions to read and write to the directories specified.

## See also

- [Photo-Sidecar-Cleaner: My script to find and remove orphaned sidecar files](https://github.com/sisyphosloughs/photo-sidecar-cleaner)
- [Move-Photos-by-Date: My script for sorting photos into folders organized by their creation date](https://github.com/sisyphosloughs/)
- [Exif (Wikipedia)](https://en.wikipedia.org/wiki/Exif)
- [Sidecar file (Wikipedia)](https://en.wikipedia.org/wiki/Sidecar_file)
- [Windows Subsystem for Linux](https://learn.microsoft.com/en-us/windows/wsl/about)
- [ExifTool by Phil Harvey](https://exiftool.org/)