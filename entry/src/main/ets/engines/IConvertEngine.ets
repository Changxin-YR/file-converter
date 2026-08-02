/**
 * 转换引擎抽象接口
 * 隔离原生 Kit 能力与三方离线引擎,支撑"尽量覆盖所有格式"的扩展目标。
 */
import { ConvertTask, ConvertResult, ConvertType } from '../common/ConvertTask'

export interface IConvertEngine {
  readonly engineName: string
  /** 是否当前原生可实现（false 表示需三方引擎） */
  readonly nativelySupported: boolean

  /** 判断该引擎能否处理：类型 + 源/目标格式 */
  supports(type: ConvertType, srcExt: string, dstExt: string): boolean

  /** 执行转换,通过回调上报进度（0-100） */
  convert(task: ConvertTask, onProgress: (percent: number) => void): Promise<ConvertResult>
}
