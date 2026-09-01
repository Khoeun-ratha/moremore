<script setup lang="ts">
import { computed, ref } from 'vue'
import { ElMessage } from 'element-plus'
import { Document, Picture, UploadFilled, VideoCamera } from '@element-plus/icons-vue'
import { uploadFile, type FileKind } from '../api/files'
import { mediaUrl } from '../utils/media'

const props = defineProps<{
  kind: FileKind
  modelValue: string | null
}>()

const emit = defineEmits<{
  'update:modelValue': [value: string]
}>()

const uploading = ref(false)

const kindIcon = computed(() => ({ video: VideoCamera, pdf: Document, image: Picture }[props.kind]))
const kindLabel = computed(() => ({ video: 'video', pdf: 'PDF', image: 'image' }[props.kind]))

const filename = computed(() => {
  if (!props.modelValue) return ''
  return props.modelValue.split('/').pop() || props.modelValue
})

async function handleChange(file: { raw?: File }) {
  if (!file.raw) return
  uploading.value = true
  try {
    const result = await uploadFile(props.kind, file.raw)
    emit('update:modelValue', result.url)
    ElMessage.success(`Uploaded ${result.filename}`)
  } catch (err) {
    ElMessage.error('Upload failed. Check the file type and size and try again.')
    throw err
  } finally {
    uploading.value = false
  }
}
</script>

<template>
  <div class="file-uploader">
    <el-upload
      drag
      :auto-upload="false"
      :show-file-list="false"
      :on-change="handleChange"
      :disabled="uploading"
      class="file-uploader__dropzone"
    >
      <div class="file-uploader__body" v-loading="uploading">
        <el-icon class="file-uploader__icon"><component :is="modelValue ? UploadFilled : kindIcon" /></el-icon>
        <div class="file-uploader__text">
          <strong>{{ modelValue ? `Replace ${kindLabel}` : `Upload ${kindLabel}` }}</strong>
          <span>Drag & drop or click to browse</span>
        </div>
      </div>
    </el-upload>

    <div v-if="modelValue" class="file-uploader__preview">
      <el-image
        v-if="kind === 'image'"
        :src="mediaUrl(modelValue)"
        fit="cover"
        class="file-uploader__thumb"
        :preview-src-list="[mediaUrl(modelValue)]"
      />
      <a v-else class="file-uploader__chip" :href="mediaUrl(modelValue)" target="_blank" rel="noopener">
        <el-icon><component :is="kindIcon" /></el-icon>
        <span>{{ filename }}</span>
      </a>
    </div>
  </div>
</template>

<style scoped>
.file-uploader {
  display: flex;
  align-items: center;
  gap: 14px;
  flex-wrap: wrap;
}

.file-uploader__dropzone {
  display: block;
}

.file-uploader__dropzone :deep(.el-upload-dragger) {
  width: auto;
  min-width: 260px;
  padding: 14px 18px;
  border-radius: var(--radius-md);
  border: 1.5px dashed var(--surface-border);
  background: var(--surface-bg);
}

.file-uploader__dropzone :deep(.el-upload-dragger:hover),
.file-uploader__dropzone :deep(.el-upload-dragger.is-dragover) {
  border-color: var(--brand-500);
  background: var(--brand-50);
}

.file-uploader__body {
  display: flex;
  align-items: center;
  gap: 12px;
  text-align: left;
}

.file-uploader__icon {
  flex-shrink: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 34px;
  height: 34px;
  border-radius: 9px;
  background: var(--brand-100);
  color: var(--brand-600);
  font-size: 17px;
}

.file-uploader__text {
  display: flex;
  flex-direction: column;
  gap: 1px;
  line-height: 1.3;
}

.file-uploader__text strong {
  font-size: 13.5px;
  color: var(--text-primary);
}

.file-uploader__text span {
  font-size: 12px;
  color: var(--text-secondary);
}

.file-uploader__preview {
  display: flex;
  align-items: center;
}

.file-uploader__thumb {
  width: 64px;
  height: 64px;
  border-radius: var(--radius-md);
  border: 1px solid var(--surface-border);
  cursor: zoom-in;
}

.file-uploader__chip {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 12px;
  border-radius: 999px;
  background: var(--brand-50);
  color: var(--brand-700);
  font-size: 12.5px;
  font-weight: 500;
  text-decoration: none;
  max-width: 220px;
}

.file-uploader__chip span {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
</style>
