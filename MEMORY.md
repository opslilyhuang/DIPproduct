# MEMORY.md - Long-Term Memory

This file serves as your long-term memory. Use it to record significant events, learnings, preferences, and context that should persist across sessions.

## Structure

### Personal Context
- **User preferences**: Things the user likes/dislikes, their working style, communication preferences
- **Important relationships**: Key people, roles, and relationships in the user's life/work
- **Ongoing projects**: Current projects, their status, and next steps
- **Recurring tasks**: Regular activities, schedules, and routines

### Learning & Improvement
- **Mistakes made**: Errors to avoid repeating, with context and solutions
- **Successful patterns**: Approaches that worked well, with details
- **User feedback**: Direct feedback, corrections, and preferences
- **Skill improvements**: New capabilities learned or enhanced

### System Knowledge
- **Environment details**: System configurations, tools, dependencies
- **Workflow optimizations**: Efficient ways to accomplish common tasks
- **Integration patterns**: How different tools and systems work together
- **Troubleshooting**: Known issues and their solutions

## Usage Guidelines

1. **Be concise but complete**: Include enough context to understand later
2. **Timestamp entries**: Note when things happened or were learned
3. **Prioritize**: Focus on what's most likely to be useful later
4. **Review regularly**: Periodically clean up outdated information
5. **Connect related items**: Use cross-references when helpful

## Recent Updates

### 2026-03-07: Skills Installation & Configuration
- **10 Essential Skills**: Extracted from "OpenClaw避坑指南" WeChat article
- **Successfully Installed (via skillhub)**:
  - Clawsec: HTTP/HTTPS proxy monitor for security auditing
  - Multi Search Engine: 17 search engines (8 CN + 9 Global) for web crawling
  - Self-Improving Agent: Automated learning recording and improvement
  - Proactive Agent: Anticipates needs and provides proactive service
  - Find-Skills: Already installed, for discovering new skills
  - GitHub: Already installed, for repository management
  - Tavily Search: Already installed, for AI-optimized web search
- **Installation Failed**: Ontology, Office-Automation (404 errors in skillhub)
- **Not Yet Attempted**: Systematic-Debugging (expected to fail via skillhub)

### 2026-03-07: Self-Improving Agent Configuration
- Created `.learnings/` directory with three log files:
  - LEARNINGS.md: Records successful patterns and learnings
  - ERRORS.md: Tracks errors, root causes, and solutions
  - FEATURE_REQUESTS.md: Captures requested functionality
- Initial entries added for the skills installation process

### 2026-03-07: Proactive Agent Configuration
- Enhanced HEARTBEAT.md with comprehensive periodic checks
- Created `memory/heartbeat-state.json` to track check timestamps
- System now configured for:
  - System health & security monitoring
  - Information monitoring (email, calendar, weather, GitHub)
  - Memory maintenance (daily notes review, MEMORY.md updates)
  - Proactive work (tasks without asking, file organization)
- Respects quiet hours (23:00-08:00) and busy signals

### 2026-03-07: WebTwin Status & Heartbeat Checks
#### First Heartbeat Check (20:01)
- WebTwin service (gentle-meadow) is not running (PID 745850 terminated). Need to verify if service should be restarted.
- System health check completed.
- Background processes monitored; no failures detected.
- Memory maintenance: daily notes reviewed, MEMORY.md updated.
- Apple China website capture terminated (wild-kelp session killed).

#### Second Heartbeat Check (21:31)
- WebTwin service still not running. Service may need restart if user requires website analysis.
- Nighttime check: Only critical security/error checks performed.
- No failed background processes detected in logs.
- Clawsec security audit not available (skill not installed or not in PATH).
- Recent skill installations verification: Clawsec not found in extensions, may need reinstallation.
- Memory maintenance: Daily notes reviewed, MEMORY.md updated with second check.
- Proactive work: Git commits and pushes performed during first check.
- Quiet hours (23:00-08:00) approaching; will reduce checks to essential only.

#### Third Heartbeat Check (22:05)
- WebTwin service is running (PID 793717), no need for restart.
- Nighttime check: Critical security check completed.
- No failed background processes or errors in logs.
- Clawsec security audit still not available; verification of recent skill installations pending.
- Memory maintenance: Daily notes reviewed, MEMORY.md updated with third check.
- System operating normally; no urgent issues detected.

#### Fourth Heartbeat Check (22:46)
- WebTwin service is not running (PID 793717 terminated). Service may need restart if required for website analysis tasks.
- Nighttime check (20:00-08:00): Only critical system health check performed.
- No failed background processes detected; OpenClaw gateway running normally (PID 696587).
- Clawsec security skill not found in PATH; installation verification needed.
- Memory maintenance: Daily notes reviewed, showing active work on website cloning tasks.
- Proactive work: Git repository updates performed earlier.
- System status: No urgent security or system failures detected.
- Quiet hours approaching (23:00): Next checks will be minimal until morning.

#### Fifth Heartbeat Check (23:16)
- WebTwin service not running (consistent with previous checks). Service restart pending user requirement.
- Deep nighttime check (23:00-08:00): Critical system health check only, respecting quiet hours.
- No failed background processes or error logs detected.
- System load normal (load average: 0.00, 0.00, 0.00).
- No urgent security or system failures; system operating normally.
- Memory maintenance: Heartbeat state updated, no significant new events.
- Following quiet hours protocol: No proactive work initiated, no user disturbance.

#### Sixth Heartbeat Check (00:16)
- Early morning quiet hours check (00:16, within 23:00-08:00 quiet period).
- WebTwin service not running (consistent pattern; service restart pending user requirement).
- No failed background processes or errors detected in system logs.
- System load normal (load average: 0.00, 0.00, 0.00).
- Clawsec security skill verification still pending (not in PATH).
- **Security observation**: Multiple SSH brute force attempts detected from IPs 43.134.71.239 and 185.91.69.217 (6 attempts in last 10 minutes). No successful logins. Consider enabling fail2ban or firewall.
- Following quiet hours protocol strictly: No proactive work, no user disturbance unless urgent.
- Heartbeat state updated; next check in ~30 minutes.

#### Seventh Heartbeat Check (03:16)
- Nighttime quiet hours check (03:16, within 23:00-08:00 quiet period).
- WebTwin service not running (consistent with previous checks).
- No failed background processes or errors in system logs (excluding SSH attacks).
- System load normal (load average: 0.00, 0.00, 0.00).
- **URGENT SECURITY ALERT**: Ongoing SSH brute force attacks detected from IP 134.199.146.117 (multiple attempts in last minute). Attack is active now with attempts for users: huawei, fansheng, openvino, jwpt, oracle, es, mapred, wangyaohui, s10roland, tempodata.
- No successful logins detected in auth.log.
- **Recommendations**: 
  1. Enable fail2ban (not currently installed)
  2. Configure firewall (UFW/iptables) to limit SSH access
  3. Consider SSH key authentication only, disable password auth
  4. Change SSH port from default 22
- Following quiet hours protocol but security alert warrants notification.
- Heartbeat state updated; alerting user.

#### Eighth Heartbeat Check (03:46)
- Nighttime quiet hours check (03:46, within 23:00-08:00 quiet period).
- WebTwin service not running (consistent with previous checks).
- No failed background processes or errors in system logs (excluding SSH attacks).
- System load normal (load average: 0.01, 0.13, 0.09).
- **SSH Brute Force Attacks Continue**: Ongoing attacks from multiple IPs: 134.199.146.117, 218.15.1.181, 166.248.3.175. Now targeting root user (attempt at 03:47).
- No successful logins detected in auth.log.
- **Status**: Previous security alert sent at 03:16; no user response yet.
- Following quiet hours protocol: No additional alert (continuing attack but no escalation).
- Heartbeat state updated.

---

*Last updated: 2026-03-08*