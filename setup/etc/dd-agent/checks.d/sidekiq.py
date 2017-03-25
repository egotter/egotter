from checks import AgentCheck
import subprocess
import re
import time

class SidekiqCheck(AgentCheck):
  def check(self, instance):
    if 'pid_file' not in instance:
      raise Exception('Sidekiq instance missing "pid_file" value.')
    pid_file = instance.get('pid_file', None)
    pid = open(pid_file, 'r').read().strip()

    name, busy_count, total_count = self.worker_count(pid)
    tag = "sidekiq_name:%s" % name.replace(':', '_')
    self.gauge('sidekiq.workers.number', total_count, tags=[tag])
    self.gauge('sidekiq.workers.busy_count', busy_count, tags=[tag])
    self.gauge('sidekiq.workers.idle_count', total_count - busy_count, tags=[tag])

    cmd="ps -o vsz= -o rss= -p %s" % pid
    vms, rss = self.exec_cmd(cmd).split()
    self.gauge('sidekiq.mem.vms', int(vms) * 1000)
    self.gauge('sidekiq.mem.rss', int(rss) * 1000)

  def worker_count(self, pid):
    # sidekiq 4.1.4 app_name [0 of 3 busy]
    cmd = "ps -o command= -p %s" % pid
    match = re.search(r'sidekiq [0-9\.]+ (\S+) \[(\d+) of (\d+) busy\]', self.exec_cmd(cmd))
    return match.group(1), int(match.group(2)), int(match.group(3))

  def exec_cmd(self, cmd):
    proc = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    out, err = proc.communicate()
    return out
