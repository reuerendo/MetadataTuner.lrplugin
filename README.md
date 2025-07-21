# MetadataTuner.lrplugin
This export filter converts diacritic characters (ą, ć, ę, ś, ź, ż, ó, ł, ń, etc.) to ASCII characters in image metadata during export.
## How to use:
1. During export, find 'Metadata Tuner' in the 'Post-Process Actions' section
2. Enable the filter
3. Export images as usual
## Processed fields:
- Title - written to EXIF:Title, XMP-dc:Title, IPTC:ObjectName
- Caption/Description - written to EXIF:Description, XMP-dc:Description, IPTC:Caption-Abstract
- Keywords - written to EXIF:Keywords, XMP-dc:Subject, IPTC:Keywords
## Requirements:
ExifTool is required for the plugin to work. You can either:
- Place ExifTool in the 'exiftool' folder inside the plugin directory (default)
- Specify custom path in the Settings section.
Download [ExifTool](https://exiftool.org/). For Windows: download the Windows Executable. For Mac/Linux: download the stand-alone executable.
