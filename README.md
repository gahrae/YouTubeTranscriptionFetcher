# YouTube Transcript Fetcher

A lightweight bash script that extracts transcripts from YouTube videos in multiple formats. Uses `yt-dlp` under the hood for reliable, authenticated-free access to YouTube subtitles.

## Features

- 🎯 **Simple CLI interface** - Just pass a video ID or full YouTube URL
- 📝 **Multiple output formats** - Plain text, JSON metadata, VTT, and SRT
- 🌍 **Language support** - Specify subtitle language (auto-generated or manual)
- 🧹 **Smart text cleaning** - Advanced deduplication and VTT parsing
- 🚫 **No authentication required** - Works without YouTube login
- ⚡ **Pure bash + awk** - No Python dependencies for text processing

## Installation

### Prerequisites

Install `yt-dlp` (choose one method):

```bash
# Using pip
pip install yt-dlp

# Using Homebrew (macOS)
brew install yt-dlp

# Using apt (Ubuntu/Debian)
sudo apt install yt-dlp

# Using pacman (Arch Linux)
sudo pacman -S yt-dlp
```

### Download the script

```bash
# Clone the repository
git clone https://github.com/yourusername/youtube-transcript-fetcher.git
cd youtube-transcript-fetcher

# Make executable
chmod +x fetch_transcript.sh
```

## Usage

### Basic Usage

```bash
# Using video ID
./fetch_transcript.sh Fg7yTKX5xxo

# Using full YouTube URL
./fetch_transcript.sh "https://www.youtube.com/watch?v=Fg7yTKX5xxo"

# Using youtu.be short URL
./fetch_transcript.sh "https://youtu.be/Fg7yTKX5xxo"
```

### Advanced Options

```bash
# Specify output format
./fetch_transcript.sh Fg7yTKX5xxo --format srt

# Choose language
./fetch_transcript.sh Fg7yTKX5xxo --lang es --format txt

# Custom output directory
./fetch_transcript.sh Fg7yTKX5xxo --output ~/Downloads

# Combine options
./fetch_transcript.sh Fg7yTKX5xxo --lang en --format json --output ./transcripts
```

### Command Line Options

| Option | Description | Default |
|--------|-------------|---------|
| `--lang LANG` | Subtitle language code (e.g., en, es, fr) | `en` |
| `--format FORMAT` | Output format: `txt`, `json`, `vtt`, `srt` | `txt` |
| `--output DIR` | Output directory path | `./transcripts` |
| `--help` | Show help message | - |

## Output Formats

### Plain Text (`txt`)
Clean, readable transcript with smart deduplication:
```
The Epstein Files. They exist. Or maybe they don't. It's a cover up.
It's a witch hunt. It's a hoax. Or maybe the whole thing is a big old nothing burger.
Maybe the Epstein files are really the friends we made along the way.
```

### JSON (`json`)
Video metadata including title, duration, description:
```json
{
  "title": "Video Title",
  "duration": 1234,
  "upload_date": "20240101",
  "description": "Video description..."
}
```

### VTT (`vtt`)
WebVTT subtitle format with timing:
```
WEBVTT

00:00:02.389 --> 00:00:04.230
The Epstein Files. They exist. Or maybe they don't.
```

### SRT (`srt`)
SubRip subtitle format (requires `ffmpeg` for conversion):
```
1
00:00:02,389 --> 00:00:04,230
The Epstein Files. They exist. Or maybe they don't.
```

## How It Works

1. **Video ID Extraction**: Parses YouTube URLs to extract 11-character video IDs
2. **yt-dlp Integration**: Uses yt-dlp to download subtitle files without the video
3. **Smart VTT Processing**: Custom awk script that:
   - Removes VTT headers and metadata
   - Strips timing information and positioning
   - Cleans HTML/XML tags
   - Performs advanced deduplication to remove overlapping text
   - Handles fragmented subtitle blocks

## Advanced Deduplication

The script includes sophisticated logic to handle YouTube's overlapping subtitle format:

**Before cleaning:**
```
The Epstein Files. They exist. Or maybe
The Epstein Files. They exist. Or maybe they don't. It's a cover up.
they don't. It's a cover up.
they don't. It's a cover up. It's a witch hunt.
```

**After cleaning:**
```
The Epstein Files. They exist. Or maybe they don't. It's a cover up. It's a witch hunt.
```

## Supported URL Formats

- `https://www.youtube.com/watch?v=VIDEO_ID`
- `https://youtube.com/watch?v=VIDEO_ID&t=30s`
- `https://youtu.be/VIDEO_ID`
- `https://m.youtube.com/watch?v=VIDEO_ID`
- `VIDEO_ID` (11 characters, direct input)

## Error Handling

The script includes comprehensive error checking:

- ✅ Validates video ID format (11 characters)
- ✅ Checks for yt-dlp installation
- ✅ Handles missing subtitles gracefully
- ✅ Provides clear error messages
- ✅ Validates command line arguments

## Requirements

- **Bash** 4.0+ (standard on most Unix systems)
- **awk** (standard on most Unix systems)
- **yt-dlp** (see installation instructions above)
- **ffmpeg** (optional, for SRT conversion)

## Limitations

- Only works with videos that have subtitles (auto-generated or manual)
- Subtitle availability depends on YouTube's policies
- Some videos may have subtitles disabled by the uploader
- Rate limiting may apply for bulk processing

## Contributing

Contributions are welcome! Please feel free to:

- Report bugs
- Suggest new features
- Submit pull requests
- Improve documentation

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built on top of [yt-dlp](https://github.com/yt-dlp/yt-dlp)
- Inspired by the need for simple, reliable YouTube transcript extraction
- Thanks to the open source community for bash scripting best practices

## Troubleshooting

### Common Issues

**"yt-dlp not found"**
```bash
# Install yt-dlp using pip
pip install yt-dlp
```

**"No subtitles available"**
- Check if the video has subtitles enabled
- Try different language codes (en, en-US, auto)
- Some videos only have auto-generated subtitles

**"Permission denied"**
```bash
# Make script executable
chmod +x fetch_transcript.sh
```

**"Invalid video ID"**
- Ensure the video ID is exactly 11 characters
- Check that the YouTube URL is accessible

### Getting Help

If you encounter issues:

1. Check the [Issues](https://github.com/yourusername/youtube-transcript-fetcher/issues) page
2. Run the script with `--help` for usage information
3. Verify yt-dlp can access the video: `yt-dlp --list-subs VIDEO_URL`

---

**Made with ❤️ for the open source community**
