from checks import AgentCheck
import subprocess
import re
import time

class UnicornCheck(AgentCheck):
  def check(self, instance):
    if 'pid_file' not in instance:
      raise Exception('Unicorn instance missing "pid_file" value.')
    pid_file = instance.get('pid_file', None)
    master_pid = open(pid_file, 'r').read().strip()
    worker_pids = self.worker_pids()

    self.gauge('unicorn.workers.number', len(worker_pids))
    self.gauge('unicorn.workers.idle_count', self.idle_worker_count(worker_pids))

    for i, pid in enumerate(worker_pids):
      cmd = "ps -o vsz= -o rss= -p %s" % pid
      vms, rss = self.exec_cmd(cmd).split()
      tag = 'worker_id:%d' % i
      self.gauge('unicorn.workers.mem.vms', int(vms) * 1000, tags=[tag])
      self.gauge('unicorn.workers.mem.rss', int(rss) * 1000, tags=[tag])

    cmd="ps -o vsz= -o rss= -p %s" % master_pid
    vms, rss = self.exec_cmd(cmd).split()
    self.gauge('unicorn.master.mem.vms', int(vms) * 1000)
    self.gauge('unicorn.master.mem.rss', int(rss) * 1000)

  def worker_pids(self):
    cmd = "ps aux | grep 'unicorn_rails worker' | grep -v grep | wc -l"
    count = int(self.exec_cmd(cmd))

    pids = []
    for i in xrange(count):
      cmd = "ps aux | grep 'unicorn_rails worker\[%d\]' | grep -v grep | awk '{ print $2 }'" % i
      pids.append(self.exec_cmd(cmd))

    return pids

  def idle_worker_count(self, worker_pids):
    before_cpu = {}
    for pid in worker_pids:
      before_cpu[pid] = self.cpu_time(pid)

    time.sleep(1)

    after_cpu = {}
    for pid in worker_pids:
      after_cpu[pid] = self.cpu_time(pid)

    count = 0
    for pid in worker_pids:
      if after_cpu[pid] == before_cpu[pid]:
        count += 1

    return count

  def cpu_time(self, pid):
    cmd = "cat /proc/%s/stat | awk '{ print $14,$15 }'" % pid
    usr, sys = self.exec_cmd(cmd).split()
    return int(usr) + int(sys)

  def exec_cmd(self, cmd):
    proc = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    out, err = proc.communicate()
    return out

