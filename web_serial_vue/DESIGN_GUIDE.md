# DTU 配置助手 - 前端设计规范

## 设计理念
参考 **Ant Design** 设计规范，采用现代简洁的 UI 风格，适合工业设备配置工具。

---

## 1. 配色系统

### 主色调
```css
--primary: #1890ff;           /* 主色 - 蓝 */
--primary-hover: #40a9ff;     /* 主色悬停 */
--primary-active: #096dd9;    /* 主色激活 */
```

### 功能色
```css
--success: #52c41a;           /* 成功 - 绿 */
--success-bg: #f6ffed;        /* 成功背景 */
--warning: #faad14;           /* 警告 - 黄 */
--warning-bg: #fffbe6;        /* 警告背景 */
--error: #ff4d4f;             /* 错误 - 红 */
--error-bg: #fff2f0;          /* 错误背景 */
```

### 文字色
```css
--text-primary: #262626;      /* 主要文字 */
--text-secondary: #595959;    /* 次要文字 */
--text-tertiary: #8c8c8c;     /* 辅助文字 */
```

### 边框与背景
```css
--border-color: #d9d9d9;     /* 边框色 */
--border-light: #f0f0f0;     /* 浅边框 */
--bg-body: #f0f2f5;          /* 页面背景 */
--bg-card: #ffffff;          /* 卡片背景 */
--bg-hover: #fafafa;         /* 悬停背景 */
```

---

## 2. 圆角系统
```css
--radius-sm: 4px;   /* 小圆角 - 下拉菜单、输入框 */
--radius-md: 8px;   /* 中圆角 - 按钮、表单项 */
--radius-lg: 12px;  /* 大圆角 - 卡片、模态框 */
```

---

## 3. 阴影系统
```css
--shadow-sm: 0 1px 2px rgba(0, 0, 0, 0.03), 0 2px 8px rgba(0, 0, 0, 0.06);
--shadow-md: 0 4px 6px rgba(0, 0, 0, 0.04), 0 8px 16px rgba(0, 0, 0, 0.08);
--shadow-lg: 0 8px 16px rgba(0, 0, 0, 0.06), 0 16px 32px rgba(0, 0, 0, 0.1);
--shadow-hover: 0 6px 12px rgba(0, 0, 0, 0.08), 0 12px 28px rgba(0, 0, 0, 0.12);
```

---

## 4. 布局规范

### 页面结构
- **头部 (Header)**: 高度 64px，固定定位，z-index: 100
- **侧边栏 (Sidebar)**: 宽度 240px
- **内容区 (Content)**: flex: 1，内边距 24px

### 卡片
```css
.card {
  background: var(--bg-card);
  border-radius: var(--radius-lg);
  border: 1px solid rgba(0, 0, 0, 0.04);
  box-shadow: var(--shadow-sm);
  margin-bottom: 24px;
  overflow: visible;  /* 重要：允许下拉菜单溢出 */
}

.card-header {
  padding: 20px 24px;
  border-bottom: 1px solid var(--border-light);
}

.card-body {
  padding: 24px;
  overflow: visible;  /* 重要：允许下拉菜单溢出 */
}
```

---

## 5. 按钮规范

### 基础按钮
```css
.btn {
  height: 40px;
  padding: 0 20px;
  border-radius: var(--radius-md);
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.25s cubic-bezier(0.4, 0, 0.2, 1);
}
```

### 按钮类型
| 类型 | 样式 | 说明 |
|------|------|------|
| `.btn-primary` | 蓝色渐变背景，白色文字 | 主要操作 |
| `.btn-default` | 白色背景，灰色边框 | 次要操作 |
| `.btn-danger` | 红色背景 | 危险操作 |
| `.btn-sm` | 高度 32px，padding 0 12px | 小尺寸 |

### 按钮状态
- `hover`: 阴影加深，向上偏移 1px
- `disabled`: 透明度 0.5，禁用指针事件

---

## 6. 表单规范

### 输入框
```css
.input {
  height: 40px;
  padding: 0 14px;
  border: 1px solid var(--border-color);
  border-radius: var(--radius-md);
  font-size: 14px;
  transition: all 0.25s;
}

.input:hover {
  border-color: var(--primary-hover);
}

.input:focus {
  outline: none;
  border-color: var(--primary);
  box-shadow: 0 0 0 3px rgba(24, 144, 255, 0.12);
}
```

### 表单项布局
```css
.form-section {
  margin-bottom: 32px;
}

.form-row {
  display: flex;
  gap: 24px;
  flex-wrap: wrap;
}

.form-item {
  flex: 1;
  min-width: 200px;
}

.form-label {
  font-size: 14px;
  color: var(--text-secondary);
  margin-bottom: 8px;
}
```

---

## 7. 选择器规范 (重要)

### 下拉菜单必须能超出容器显示

```css
/* 容器必须设置 */
.card, .card-body, .modal-body, .form-section {
  overflow: visible;
}

/* 下拉菜单 */
.select {
  position: relative;
}

.select-trigger {
  height: 40px;
  padding: 0 32px 0 12px;
  border: 1px solid var(--border-color);
  border-radius: var(--radius-sm);
  cursor: pointer;
}

.select-dropdown {
  position: absolute;
  top: calc(100% + 4px);
  left: 0;
  right: 0;
  background: var(--bg-card);
  border: 1px solid var(--border-color);
  border-radius: var(--radius-sm);
  box-shadow: var(--shadow-lg);
  z-index: 1001;           /* 必须高于模态框的 z-index: 1000 */
  max-height: 256px;
  overflow-y: auto;
}

.select-option {
  padding: 10px 12px;
  font-size: 14px;
  cursor: pointer;
}

.select-option:hover {
  background: var(--bg-hover);
}

.select-option.selected {
  background: rgba(24, 144, 255, 0.08);
  color: var(--primary);
  font-weight: 500;
}
```

---

## 8. 模态框规范

```css
.modal {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.45);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal-content {
  background: var(--bg-card);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-lg);
  min-width: 500px;
  max-width: 90vw;
}

.modal-header {
  padding: 20px 24px;
  border-bottom: 1px solid var(--border-light);
}

.modal-body {
  padding: 24px;
  max-height: 75vh;
  overflow-y: auto;
  overflow-x: visible;  /* 允许横向溢出 */
}

.modal-footer {
  padding: 16px 24px;
  border-top: 1px solid var(--border-light);
}
```

---

## 9. 状态指示器

### 连接状态徽章
```css
.status-badge {
  padding: 6px 14px;
  border-radius: 20px;
  font-size: 13px;
  font-weight: 600;
}

.status-badge.connected {
  background: var(--success-bg);
  color: var(--success);
}

.status-badge.connecting {
  background: var(--warning-bg);
  color: var(--warning);
}

.status-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  animation: statusPulse 2s infinite;
}

@keyframes statusPulse {
  0%, 100% { box-shadow: 0 0 0 3px rgba(82, 196, 26, 0.2); }
  50% { box-shadow: 0 0 0 5px rgba(82, 196, 26, 0.1); }
}
```

---

## 10. 字体规范

```css
font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;

.header-title {
  font-size: 20px;
  font-weight: 700;
  letter-spacing: -0.5px;
}

.card-title {
  font-size: 16px;
  font-weight: 600;
}

.form-label {
  font-size: 14px;
}

.input, .select, .btn {
  font-size: 14px;
}
```

---

## 11. 动画规范

```css
--transition: all 0.25s cubic-bezier(0.4, 0, 0.2, 1);

/* 常用动画效果 */
hover: translateY(-1px) + box-shadow 增强
active: translateY(0) + 轻微缩小
展开/收起: rotate(180deg) 用于箭头图标
脉冲: statusPulse 2s infinite
淡入: opacity 0 -> 1
```

---

## 12. 响应式断点

```css
/* 平板 (768px 以下) */
.serial-params-bar {
  grid-template-columns: 1fr 1fr;
}

/* 手机 (480px 以下) */
.serial-params-bar {
  grid-template-columns: 1fr;
}
```

---

## 关键注意事项

1. **下拉菜单溢出问题**: 所有容器（`.card`, `.modal-body`, `.form-section`）必须设置 `overflow: visible`，下拉菜单的 `z-index` 必须高于模态框。

2. **模态框高度**: 建议设置 `max-height: 75vh` 和 `overflow-y: auto`，确保内容可滚动。

3. **阴影层次**: 
   - 小阴影用于卡片
   - 中阴影用于模态框
   - 大阴影用于下拉菜单

4. **按钮渐变**: 主按钮使用 `linear-gradient(135deg, ...)` 实现立体感。

5. **过渡动画**: 所有交互元素都应使用 `cubic-bezier(0.4, 0, 0.2, 1)` 缓动函数。
