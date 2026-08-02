/**
 * 转换任务数据模型
 * 定义转换状态机、转换类型与任务/结果数据结构。
 */

export enum ConvertStatus {
  PENDING = 'pending',
  CONVERTING = 'converting',
  SUCCESS = 'success',
  FAILED = 'failed'
}

export enum ConvertType {
  DOCUMENT = 'document',
  IMAGE = 'image',
  AUDIO = 'audio',
  VIDEO = 'video'
}

/** 转换选项（图片质量/尺寸、音频码率/采样率、文档编码） */
export interface ConvertOptions {
  quality?: number          // 图片质量 1-100
  width?: number            // 目标宽度（可选）
  height?: number           // 目标高度（可选）
  keepAspectRatio?: boolean // 图片保持宽高比，默认 true
  audioBitrate?: number     // 音频码率
  audioSampleRate?: number  // 音频采样率
  sourceEncoding?: string   // 文档源编码，如 utf-8 / utf-16le / gbk
  targetEncoding?: string   // 文档目标编码，默认 utf-8
}

/** 一次转换任务 */
export interface ConvertTask {
  id: string
  type: ConvertType
  sourcePath: string
  sourceFormat: string
  targetFormat: string
  targetPath?: string
  status: ConvertStatus
  progress: number
  createTime: number
  completeTime?: number
  fileSize?: number
  errorMsg?: string
  options?: ConvertOptions
}

/** 转换结果 */
export interface ConvertResult {
  success: boolean
  targetPath?: string
  errorMsg?: string
}
