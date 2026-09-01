import http from './http'
import type { Certificate, Page } from '../types/api'

export interface CertificateListParams {
  q?: string
  user_id?: number
  course_id?: number
  page?: number
  page_size?: number
}

export function listCertificates(params: CertificateListParams) {
  return http.get<Page<Certificate>>('/certificates', { params }).then((r) => r.data)
}

export function getCertificate(id: number) {
  return http.get<Certificate>(`/certificates/${id}`).then((r) => r.data)
}
