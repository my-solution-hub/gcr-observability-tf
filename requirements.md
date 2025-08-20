# 可观测性需求

## 1. 自定义仪表板 (Customized Dashboard)

### 应用层监控 - CloudWatch Endpoint

- **性能指标**：P99、P95响应时间（目标阈值：150ms）
- **可用性监控**：服务可用性指标
- **系统资源**：CPU使用率（用户态）、内存使用率、磁盘使用率
- **业务指标**：错误率监控
- **深度分析**：支持图表深入钻取，监控所有关键指标
- **业务需求**：每个微服务独立Dashboard，5分钟刷新频率，cloudwatch触发alarm

### 数据库监控

- **RDS/Aurora**：使用CloudWatch Database Insights进行数据库性能监控
- **缓存监控**：CloudWatch ElastiCache监控Redis缓存命中率

## 2. 代码级指标创建 (Create Metrics in Source Code)

- **实施方式**：在应用程序源代码中嵌入自定义指标
- **技术方案**：
  - Python：自动插桩类增强（runtime hook）
  - Java：字节码增强自动插桩
- **目标**：实现应用程序性能的精细化监控，日志保留14天传到datalake做debug

## 3. 关键指标告警 (Create Alerts)

- **告警阈值**：关键指标超过300ms触发告警
- **告警机制**：基于CloudWatch Alarm配置
- **覆盖范围**：所有关键业务指标

## 4. PagerDuty集成 (PagerDuty Integration)

- **通知方式**：短信和电话呼叫（每周1个on call eng&mgr）
- **技术架构**：CloudWatch Alert → SNS → HTTP/Lambda → PagerDuty回调
- **目标**：确保关键事件及时响应

## 5. 事件分析 (Incident Analysis)

- **全球集成**：连接PagerDuty Global系统
- **分析能力**：支持事件根因分析和趋势分析
- **协作**：与全球团队协同处理重大事件

## 6. 按需付费模式 (Pay as You Go)

### 成本结构

- **日志成本**：数据摄取占95%成本，存储占5%成本
- **存储容量**：10GB-50GB/d
- **用户分层**：程序员 & 市场销售
- **日志类**：Standard Class存储、Infrequent Class存储（目前看上去大部分可以log可以放置）

### 成本监控

- **日报机制**：每日生成详细账单报告
- **成本优化**：根据访问模式选择合适的存储类别

### CICD

- 目前Global用的conveyor
- 考虑在国内用Gitlab做repo，与conveyor集成，Canary方式部署微服务

## 7. 目前在考虑的方案

### 第三方方案

观测云

### AWS 沟通方案

**基本操作**：对于任何解决方案都需要做的部分

**额外操作**：针对AWS 中国区当前功能提供情况需要额外进行的操作

**技术栈**：自动采集 + OpenTelemetry Collector + Cloudwatch APM（Application Signals trace / metrics / logs / runtime data）+ Grafana Faro

#### App / Web 监控

1. **[基本操作]** 边缘监控需要集成 SDK/javascript 脚本 - 使用 开源工具 [Grafana Faro](https://github.com/grafana/faro-web-sdk?tab=readme-ov-file) / [OpenTelemetry](https://opentelemetry.io/docs/languages/js/getting-started/browser/) 总的来说，边缘都需要以集成 SDK 的方式进行集成，指标等资源需要发送到 OpenTelemetry Collector 进行存储。

2. **[额外操作]** 边缘业务想要发送数据需要鉴权 - 在 OpenTelemetry Collector 中设置 API Key 来做校验，或者提供用户的 JWT / Bearer Token等 来做校验。由于 CloudWatch RUM 功能在中国区不提供因此需要自己配置一个简单的鉴权方式

#### 业务 App 部署

- **[基本操作]** 采集使用python 和 Java 的 auto-instrumentation，对业务代码无侵入，数据发送到 OpenTelemetry Collector 走内网，无需鉴权。这个操作是所有监控工具或者方案都需要的。

#### OpenTelemetry Collector

在 EC2 / EKS 安装 OpenTelemetry Collector 进行数据采集，加工。通过角色绑定的方式发送数据存储到 CloudWatch

- **[基本操作]** 安装统一的 OpenTelemetry Collector 进行数据采集，并配置 ALB 进行端点暴露

#### 制作 RUM，API 等数据大盘

- **[基本操作] [额外操作]** 在 CloudWatch 上协助客户配置大盘

### 部署方式

1. 使用 自动化工具基于 AWS 的基础镜像制作APP镜像，确保 pip install 和 Java agent 默认存在
2. 配置 OpenTelemetry Collector 进行采集
3. 配置后端数据大盘
4. 配置 RUM 前端 SDK
5. 配置前端数据大盘

K8S、虚机配置、python 库、redis版本、java（Spring Cloud）&python（Flask/Django）
