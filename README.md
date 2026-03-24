# EasyStore - 简易仓库管理系统

EasyStore 是一个轻量级的仓库与物品管理系统，旨在提供简单、直观的库存跟踪与管理功能。本项目采用 Vue 3 + Vite 作为前端框架，FastAPI + SQLite 作为后端框架。

## 主要功能
- **仪表盘**：查看库存总览、核心指标和最近的操作流水。
- **库存管理**：查看当前库存，物品入库、出库。支持低库存预警提示。
- **流转记录**：详细记录每一次入库和出库操作，方便追溯。
- **元数据管理**：管理物品的分类、品牌、单位以及用途。
- **权限管理**：区分 Admin（管理员）和 User（普通用户）角色。普通用户只能查看库存，管理员可执行出入库和元数据管理等操作。

## 目录结构
- `/web`: 前端项目目录（Vue 3 + TypeScript + Element Plus + Tailwind CSS）
- `/server`: 后端项目目录（FastAPI + SQLAlchemy + SQLite）
- `/docs`: 项目文档（包含需求、设计、计划等）

## 一键运行方式 (Windows)

在 Windows 环境下，直接右键点击项目根目录下的 `start.ps1`，选择 **使用 PowerShell 运行**。
该脚本会自动完成以下操作：
1. 进入 `web` 目录构建前端生产代码。
2. 进入 `server` 目录创建并激活 Python 虚拟环境，安装依赖。
3. 启动 FastAPI 服务，并自动在浏览器中打开 `http://127.0.0.1:8000`。
   *(注：FastAPI 配置了对前端打包后产物的静态托管)*

## 默认账号

- **管理员**：
  - 用户名：`admin`
  - 密码：`123456`
- **普通用户**：
  - 用户名：`user`
  - 密码：`123456`

## 手动开发运行

### 前端 (Web)
```bash
cd web
npm install
npm run dev
```
前端默认运行在 `http://localhost:5174`。

### 后端 (Server)
```bash
cd server
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
pip install "bcrypt<4.0.0"
python main.py
```
后端服务默认运行在 `http://127.0.0.1:8000`。

## 许可证
MIT License
