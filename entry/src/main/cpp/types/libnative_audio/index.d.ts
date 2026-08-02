export const convertWavToM4a: (sourceFd: number, targetFd: number, bitrate: number) => Promise<void>
export const extractMp4AudioToM4a: (
  sourceFd: number,
  sourceSize: number,
  targetFd: number
) => Promise<void>
export const remuxMovToMp4: (
  sourceFd: number,
  sourceSize: number,
  targetFd: number
) => Promise<void>
