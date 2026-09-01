import http from './http'
import type { FileUploadResult } from '../types/api'

export type FileKind = 'video' | 'pdf' | 'image'

export function uploadFile(kind: FileKind, file: File) {
  const formData = new FormData()
  formData.append('file', file)
  return http
    .post<FileUploadResult>('/files/upload', formData, {
      params: { kind },
      headers: { 'Content-Type': 'multipart/form-data' },
    })
    .then((r) => r.data)
}
