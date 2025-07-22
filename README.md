# MetadataTuner.lrplugin
This export filter converts diacritic characters (ą, ć, ę, ś, ź, ż, ó, ł, ń, etc.) to ASCII characters in image metadata during export.

The plugin allows you to add information from other tags to the **title** and **caption** fields using a mask. This is useful, for example, when exporting editorial photos for shutterstock.
### Available placeholders:
#### Date & Time:
{YYYY} - Full year (2024)

{YY} - Short year (24)

{MM} - Month with zero (01-12)

{MMM} - Short month name (Jan)

{MMMM} - Full month name (January)

{DD} - Day with zero (01-31)

{D} - Day without zero (1-31)

{DDD} - Short day name (Mon)

{DDDD} - Full day name (Monday)
#### Location:
{City} - City name

{State} - State/Province

{Country} - Country name

{Location} - Location field

{Sublocation} - Sublocation field
#### Metadata:
{Title} - Photo title

{Caption} - Photo caption

{Keywords} - Keywords list
## How to use:
1. During export, find 'Metadata Tuner' in the 'Post-Process Actions' section
2. Enable the filter
3. Export images as usual
## Processed fields:
- Title - written to EXIF:Title, XMP-dc:Title, IPTC:ObjectName
- Caption/Description - written to EXIF:Description, XMP-dc:Description, IPTC:Caption-Abstract
## Requirements:
**ExifTool is required** for the plugin to work. You can either:
- Place ExifTool in the 'exiftool' folder inside the plugin directory (default)
- Specify custom path in the Settings section.

Download [ExifTool](https://exiftool.org/). For Windows: download the Windows Executable. For Mac/Linux: download the stand-alone executable.
