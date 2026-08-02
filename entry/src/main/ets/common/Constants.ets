/**
 * 全局常量
 * 断点系统、网格列数与文件后缀过滤。
 */

export class BreakpointConstants {
  static readonly BREAKPOINT_SM: number = 320  // phone 竖屏
  static readonly BREAKPOINT_MD: number = 600  // phone 横屏 / 小 tablet
  static readonly BREAKPOINT_LG: number = 840  // tablet / 2in1
}

export class GridConstants {
  static readonly SM_COLUMNS: number = 2
  static readonly MD_COLUMNS: number = 3
  static readonly LG_COLUMNS: number = 4
}

export class StorageConstants {
  static readonly IMAGE_SUFFIXES: string[] = ['.png', '.jpg', '.jpeg', '.webp', '.bmp', '.gif', '.heic', '.heif']
  static readonly AUDIO_SUFFIXES: string[] = ['.mp3', '.aac', '.m4a', '.flac', '.wav', '.ogg']
  static readonly DOCUMENT_SUFFIXES: string[] = ['.txt', '.csv', '.json', '.xml', '.html', '.md', '.log']
  static readonly ARCHIVE_SOURCE_SUFFIXES: string[] = [
    '.txt', '.log', '.csv', '.json', '.xml', '.md', '.html', '.pdf',
    '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx',
    '.jpg', '.jpeg', '.png', '.webp', '.bmp', '.gif',
    '.mp3', '.m4a', '.aac', '.wav', '.flac', '.ogg',
    '.mp4', '.mov', '.avi', '.mkv', '.zip'
  ]
}

export class AudioPreset {
  static readonly BITRATES: number[] = [64000, 128000, 192000, 320000]
  static readonly SAMPLE_RATES: number[] = [44100, 48000]
}
