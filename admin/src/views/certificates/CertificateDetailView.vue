<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ArrowLeft, Medal, TrendCharts } from '@element-plus/icons-vue'
import { getCertificate } from '../../api/certificates'
import type { Certificate } from '../../types/api'

const props = defineProps<{ certificateId: number }>()
const router = useRouter()

const certificate = ref<Certificate | null>(null)
const loading = ref(true)

onMounted(async () => {
  try {
    certificate.value = await getCertificate(props.certificateId)
  } finally {
    loading.value = false
  }
})

function formatDate(value: string) {
  return new Date(value).toLocaleDateString(undefined, { year: 'numeric', month: 'long', day: 'numeric' })
}

function viewProgress() {
  if (certificate.value) router.push({ name: 'user-progress', params: { id: certificate.value.user_id } })
}
</script>

<template>
  <el-button text :icon="ArrowLeft" class="back-link" @click="router.push({ name: 'certificates' })">
    Back to certificates
  </el-button>

  <div class="page-header">
    <div>
      <h2>Certificate detail</h2>
      <p>Full record for this issued certificate.</p>
    </div>
    <div class="page-header__actions" v-if="certificate">
      <el-button :icon="TrendCharts" @click="viewProgress">View learner progress</el-button>
    </div>
  </div>

  <div v-loading="loading">
    <template v-if="certificate">
      <div class="certificate-card">
        <el-icon class="certificate-card__icon"><Medal /></el-icon>
        <div class="certificate-card__kicker">Certificate of completion</div>
        <div class="certificate-card__label">This certifies that</div>
        <div class="certificate-card__name">{{ certificate.user_full_name }}</div>
        <div class="certificate-card__label">has successfully completed</div>
        <div class="certificate-card__course">{{ certificate.course_title }}</div>
        <div class="certificate-card__meta">
          <span>{{ formatDate(certificate.issued_at) }}</span>
          <span class="certificate-card__dot">&middot;</span>
          <code>{{ certificate.certificate_number }}</code>
        </div>
      </div>

      <div class="surface-card details-card">
        <div class="details-row">
          <span class="details-row__label">Learner</span>
          <span class="details-row__value">{{ certificate.user_full_name }} ({{ certificate.user_email }})</span>
        </div>
        <div class="details-row">
          <span class="details-row__label">Course</span>
          <span class="details-row__value">{{ certificate.course_title }}</span>
        </div>
        <div class="details-row">
          <span class="details-row__label">Certificate number</span>
          <span class="details-row__value"><code>{{ certificate.certificate_number }}</code></span>
        </div>
        <div class="details-row">
          <span class="details-row__label">Issued</span>
          <span class="details-row__value">{{ formatDate(certificate.issued_at) }}</span>
        </div>
      </div>
    </template>
  </div>
</template>

<style scoped>
.certificate-card {
  max-width: 480px;
  margin: 0 auto 20px;
  padding: 36px 28px;
  text-align: center;
  background: var(--surface-card);
  border: 2px solid var(--brand-500);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-md);
}

.certificate-card__icon {
  font-size: 40px;
  color: #d99a1b;
  margin-bottom: 12px;
}

.certificate-card__kicker {
  font-size: 12.5px;
  font-weight: 700;
  letter-spacing: 1px;
  text-transform: uppercase;
  color: var(--text-primary);
  margin-bottom: 20px;
}

.certificate-card__label {
  font-size: 13px;
  color: var(--text-secondary);
  margin-top: 12px;
}

.certificate-card__name {
  font-size: 20px;
  font-weight: 700;
  margin-top: 4px;
}

.certificate-card__course {
  font-size: 18px;
  font-weight: 700;
  color: var(--brand-600);
  margin-top: 4px;
}

.certificate-card__meta {
  margin-top: 24px;
  font-size: 12.5px;
  color: var(--text-secondary);
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
}

.certificate-card__dot {
  color: var(--surface-border);
}

.details-card {
  max-width: 480px;
  margin: 0 auto;
}

.details-row {
  display: flex;
  justify-content: space-between;
  gap: 16px;
  padding: 10px 0;
  border-bottom: 1px solid var(--surface-border);
  font-size: 13.5px;
}

.details-row:last-child {
  border-bottom: none;
}

.details-row__label {
  color: var(--text-secondary);
}

.details-row__value {
  font-weight: 500;
  text-align: right;
}

code {
  font-size: 12.5px;
  background: var(--brand-50);
  color: var(--brand-700);
  padding: 2px 6px;
  border-radius: 6px;
}
</style>
