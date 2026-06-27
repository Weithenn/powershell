import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import { exec } from "child_process";
import { promisify } from "util";
import fs from "fs";
import path from "path";
import os from "os"; // 引入 Node.js 內建的 OS 模組，用於抓取身分
const execAsync = promisify(exec);
// ==========================================
// 1. 初始化日誌機制與精準身分抓取
// ==========================================
const LOG_FILE_PATH = path.join(process.cwd(), "audit.log");
function writeLog(level, message) {
  const timestamp = new Date().toISOString();
  // 自動抓取當前系統登入的用戶名稱 (例如: Weithenn)
  let username = "UNKNOWN_USER";
  try {
    username = os.userInfo().username;
  } catch (e) {
    // 防止某些極端環境下無法獲取用戶名導致程式崩潰
  }
  // 格式化日誌：加入 [OPERATOR: 使用者]
  const logMessage = `[${timestamp}] [${level}] [OPERATOR: ${username}] ${message}\n`;
  
  // 同步寫入實體檔案
  fs.appendFileSync(LOG_FILE_PATH, logMessage, "utf8");
}
// ==========================================
// 2. 初始化 MCP Server
// ==========================================
const server = new Server(
  {
    name: "windows-admin-server",
    version: "1.0.0",
  },
  {
    capabilities: {
      tools: {},
    },
  }
);
// 🛡️ 安全治理核心：定義合法的服務白名單
const ALLOWED_SERVICES = [
  "w3svc",             // IIS 網頁伺服器
  "spooler",           // Print Spooler 列印慢存區
  "dhcp",              // DHCP Client
  "dnscache"           // DNS Cache
];
// ==========================================
// 3. 註冊工具清單 (List Tools)
// ==========================================
server.setRequestHandler(ListToolsRequestSchema, async () => {
  writeLog("SYSTEM", "=== Windows Admin MCP Server 正在查詢可用的 MCP 工具清單 ===");
  return {
    tools: [
      {
        name: "windows_admin_server_check_windows_service",
        description: "檢查指定 Windows 系統服務的當前狀態。",
        inputSchema: {
          type: "object",
          properties: {
            serviceName: {
              type: "string",
              description: "要檢查的 Windows 服務名稱 (例如: spooler)",
            },
          },
          required: ["serviceName"],
        },
      },
      {
        name: "windows_admin_server_restart_windows_service",
        description: "安全地重新啟動指定的 Windows 系統服務（需要白名單資安審查）。",
        inputSchema: {
          type: "object",
          properties: {
            serviceName: {
              type: "string",
              description: "要重啟的 Windows 服務名稱 (例如: spooler)",
            },
          },
          required: ["serviceName"],
        },
      },
    ],
  };
});
// ==========================================
// 4. 處理工具執行邏輯 (Call Tool)
// ==========================================
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;
  const serviceName = args?.serviceName?.toLowerCase().trim();
  if (!serviceName) {
    return {
      content: [{ type: "text", text: "錯誤：未提供服務名稱。" }],
      isError: true,
    };
  }
  // ---- 工具 A：檢查服務狀態 ----
  if (name === "windows_admin_server_check_windows_service") {
    writeLog("AUDIT", `接收到 AI 工具請求 ➔ 查詢服務狀態: [${serviceName}]`);
    
    try {
      // 安全考量：使用 PowerShell 原生指令，避免拼接字串引發 Injection
      const { stdout } = await execAsync(
        `powershell -Command "Get-Service -Name '${serviceName}' | Select-Object -ExpandProperty Status"`
      );
      const status = stdout.trim();
      
      writeLog("SUCCESS", `服務 [${serviceName}] 狀態查詢成功 ➔ 當前狀態為: [${status}]`);
      return {
        content: [{ type: "text", text: `Windows 服務 '${serviceName}' 當前狀態為: ${status}` }],
      };
    } catch (error) {
      writeLog("ERROR", `查詢服務 [${serviceName}] 失敗 ➔ 錯誤原因: ${error.message}`);
      return {
        content: [{ type: "text", text: `無法獲取服務 '${serviceName}' 的狀態，請確認服務名稱是否正確。` }],
        isError: true,
      };
    }
  }
  // ---- 工具 B：安全重啟服務 (內含零信任白名單) ----
  if (name === "windows_admin_server_restart_windows_service") {
    writeLog("SECURITY_ALERT", `AI 申請執行敏感操作 ➔ 企圖重新啟動服務: [${serviceName}]`);
    // 零信任白名單資安檢查
    if (!ALLOWED_SERVICES.some(allowed => serviceName.includes(allowed))) {
      writeLog("SECURITY_REJECT", `【資安攔截】服務 [${serviceName}] 不在白名單內，拒絕執行！`);
      return {
        content: [{ type: "text", text: `【資安拒絕】服務 '${serviceName}' 未包含在核准的白名單中。操作已被安全閘門強制攔截。` }],
        isError: true,
      };
    }
    writeLog("AUDIT", `重啟安全審核通過。開始執行 PowerShell Restart-Service: [${serviceName}]`);
    
    try {
      await execAsync(`powershell -Command "Restart-Service -Name '${serviceName}' -Force"`);
      writeLog("SUCCESS", `服務 [${serviceName}] 成功重新啟動！`);
      return {
        content: [{ type: "text", text: `Windows 服務 '${serviceName}' 已成功安全地重新啟動。` }],
      };
    } catch (error) {
      writeLog("ERROR", `重啟服務 [${serviceName}] 失敗 ➔ 錯誤原因: ${error.message}`);
      return {
        content: [{ type: "text", text: `執行重啟指令時發生錯誤: ${error.message}` }],
        isError: true,
      };
    }
  }
  return {
    content: [{ type: "text", text: `未知的工具名稱: ${name}` }],
    isError: true,
  };
});
// ==========================================
// 5. 啟動伺服器傳輸機制
// ==========================================
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  writeLog("SYSTEM", "=== Windows Admin MCP Server 已成功啟動 ===");
}
main().catch((error) => {
  writeLog("CRITICAL", `MCP Server 崩潰: ${error.message}`);
  process.exit(1);
});