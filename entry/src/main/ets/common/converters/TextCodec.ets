/**
 * 文本编解码封装
 * 基于 util.TextDecoder / TextEncoder（ICU）。
 * 解码支持多种编码（UTF-8 / UTF-16LE / GBK 等）；
 * 编码输出固定 UTF-8（API 22 TextEncoder 仅支持 UTF-8）。
 */
import { util } from '@kit.ArkTS'

export class TextCodec {
  /** 字节数组 → 字符串（支持 utf-8 / utf-16le / gbk 等） */
  static decode(buffer: ArrayBuffer, encoding: string = 'utf-8'): string {
    const decoder = util.TextDecoder.create(encoding)
    return decoder.decodeToString(new Uint8Array(buffer))
  }

  /** 字符串 → UTF-8 字节数组（API 22 仅支持 UTF-8 编码输出） */
  static encode(text: string): ArrayBuffer {
    const encoder = new util.TextEncoder()
    return encoder.encodeInto(text).buffer
  }
}
