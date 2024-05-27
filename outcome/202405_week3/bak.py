"""
此文件用于备份
"""

import copy
from enum import Enum
import json
import time
import os
import libvirt
from typing import Callable, List

import pyautotest


class VM:

    def __init__(self, name: str, domain_xml_str: str):
        self.conn = libvirt.open("qemu:///system")

        # https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/virtualization_deployment_and_administration_guide/sect-troubleshooting-common_libvirt_errors_and_troubleshooting
        # libvirtd.service

        # start default network
        network_name = "default"
        net = self.conn.networkLookupByName(network_name)
        if not net.isActive():
            net.create()

        # stop vm if active
        try:
            dom = self.conn.lookupByName(name)
            print("has old vm")
            if dom.isActive():
                # print("active, stopping...")
                # dom.shutdown()
                # dom.destroy()
                time.sleep(1)
            else:
                dom.create()
                # dom.undefine()
            self.dom = dom
        except Exception as e:
            print("no old vm", e)
            print("creating new vm")
            dom = self.conn.defineXML(domain_xml_str)
            dom.create()
            self.dom = dom

        # create vm
        print("done, active now")

    def stop(self):
        if self.dom != None and self.dom.isActive():
            print("active, stopping...")
            self.dom.shutdown()
            self.dom.destroy()
            time.sleep(1)

        # self.dom.undefine()

    def save_snapshot(self, name, description="", override=False):
        if self.get_snapshot_by_name(name) == None:
            pass
        elif override:
            self.delete_snapshot_by_name(name)
        else:
            return

        snapshot_xml = f"""
        <domainsnapshot>
        <name>{name}</name>
        <description>{description}</description>
        </domainsnapshot>
        """
        self.dom.snapshotCreateXML(snapshot_xml, 0)

    def save_snapshot_and_jump(self, name, description="", override=False):
        self.save_snapshot(name, description, override)
        self.jump_to_snapshort(name)

    def jump_to_snapshort(self, name):
        snap = self.get_snapshot_by_name(name)
        if snap == None:
            raise "snap not exist"
        self.dom.revertToSnapshot(snap)

    def get_snapshot_by_name(self, name):
        try:
            snap = self.dom.snapshotLookupByName(name)
            return snap
        except:
            return None

    def delete_snapshot_by_name(self, name):
        try:
            snap = self.dom.snapshotLookupByName(name)
            snap.delete()
        except:
            pass

    def delete_all_snapshot(self):
        for name in self.dom.snapshotListNames():
            snap = self.dom.snapshotLookupByName(name)
            snap.delete()


class Status(Enum):
    EMPTY = "empty"
    PASS = "pass"
    FAIL = "fail"
    SKIP = "skip"


class Job:
    fn: Callable[[pyautotest.Driver], bool]
    status: Status
    skip: bool
    children: List["Job"]

    @property
    def name(self) -> str:
        return self.fn.__name__

    def serialize_dict(self) -> str:
        return {"name": self.name, "status": self.status.value, "children": []}

    def serialize_str(self) -> str:
        return json.dumps(self.serialize_dict())

    def __init__(self, case_fn, children=[], skip=False):
        self.fn = case_fn
        self.children = children
        self.status = Status.EMPTY
        self.skip = skip


def get_timestamp():
    return int(time.time())


class DB:
    _value: dict
    _store: str

    def __init__(self, store: str = "./db.json"):
        self._store = store
        if not os.path.exists(store):
            with open(store, "w") as f:
                f.write("{}")
                f.close()
        self._value = json.loads(open(store, "r").read())

    def save(self):
        json.dump(self._value, open(self._store, "w"))

    def use(self, scope: str) -> dict:
        if self._value.get(scope) == None:
            self._value[scope] = {}
        return self._value[scope]


class Workflow:
    name: str
    jobs: List[Job]
    db: DB

    def __init__(
        self, name: str, vm: VM, d: pyautotest.Driver, jobs: List[Job], db: DB = DB()
    ):
        self.name = name
        self.d = d
        self.vm = vm
        self.db = db

        name_map = {}

        def check_name_duplicate(job: Job):
            if name_map.get(job.name) != None:
                raise Exception("duplicate job name: " + job.name)
            else:
                name_map[job.name] = ""
            return True

        self.work_jobs(jobs, check_name_duplicate)

        self.jobs = jobs

    @staticmethod
    def work_jobs(jobs: List[Job], f: Callable[[Job], bool]):
        for job in jobs:
            if f(job):
                Workflow.work_jobs(job.children, f)

    def run(self, base_snapname: str = "init"):
        # 创建初始快照
        self.vm.save_snapshot(base_snapname)
        self._run(base_snapname, self.jobs, [])

    # 运行
    def _run(self, base_snapname: str, jobs: List[Job], _indexs: List[int]):
        for i, job in enumerate(jobs):

            indexs = copy.deepcopy(_indexs)
            indexs.append(i + 1)
            indexs_str = ".".join(map(lambda x: str(x), indexs))

            case_fn = job.fn
            next_snapname = case_fn.__name__
            print(f"running case {indexs_str}: {case_fn.__name__}, result: ", end="")

            if job.skip:
                job.status = Status.SKIP
                print("hand_skip")
                continue

            try:
                # 如果之前运行过没有通过，或者无镜像保留，就运行跳过
                if (
                    job.status != Status.PASS
                    or self.vm.get_snapshot_by_name(next_snapname) == None
                ):
                    # 每个 job 运行前跳转到初始快照
                    self.vm.jump_to_snapshort(base_snapname)

                    case_fn(self.d)

                    job.status = Status.PASS
                    # 测试通过快照
                    self.vm.save_snapshot(next_snapname)
                    print("pass")
                else:
                    print("pass(skip)")

                try:
                    self._run(next_snapname, job.children, indexs)
                except Exception as e:
                    pass

            except Exception as e:
                job.status = Status.FAIL
                print("fail")
                # 测试失败快照
                self.vm.save_snapshot(next_snapname + "-failed")
                continue

    # 打印
    def __str__(self):
        indent = 0
        res = ""

        def _print_job(job: Job, indent: int):
            res = ""
            job_name = job.fn.__name__
            job_status = job.status.value
            res += f'{" " * indent}- {job_name}: {job_status}\n'
            for child in job.children:
                res += _print_job(child, indent + 2)
            return res

        for job in self.jobs:
            res += _print_job(job, indent)

        return res

    def save_result(self):
        def serialize_dict():
            res = {}

            def _serialize_job(job):
                res[job.name] = job.serialize_dict()
                for child in job.children:
                    _serialize_job(child)
                return True

            self.work_jobs(self.jobs, _serialize_job)
            return res

        def serialize_str(self):
            return json.dumps(self.serialize_dict())

        self.db.use(self.name)[get_timestamp()] = serialize_dict()
        self.db.save()

    def load_result(self):

        def _deserialize_dict(data: dict) -> dict[str, Status]:
            res = {}

            def _deserialize_job(job_map: dict):
                for name, info in job_map.items():
                    res[name] = info["status"]
                    for child in info["children"]:
                        _deserialize_job(child)

            _deserialize_job(data)
            return res

        def _load_latest_workflow() -> dict[str, Status]:
            time_list = [int(i) for i in self.db.use(self.name).keys()]
            if len(time_list) == 0:
                return {}

            time_list.sort()
            max_timestamp = str(time_list[-1])
            return _deserialize_dict(self.db.use(self.name).get(max_timestamp))

        results = _load_latest_workflow()

        def _set_status(job: Job):
            if results.get(job.name) is not None:
                status = Status(results.get(job.name))
                if status != Status.PASS:
                    return False
                job.status = status
                return True

        self.work_jobs(self.jobs, _set_status)


def test_case_boot(d: pyautotest.Driver):
    # exec("""
    d.assert_screen("wait_press_ecs_goto_boot_menu", 10)

    d.send_key("esc")

    d.assert_screen("press_ecs_goto_boot_menu", 10)
    # """)
    pass


def test_case1_1(d: pyautotest.Driver):
    pass


def test_case1_1_1(d: pyautotest.Driver):
    pass


def test_case1_2(d: pyautotest.Driver):
    pass


def test_case2(d: pyautotest.Driver):
    pass


if __name__ == "__main__":
    vm = None
    d = None
    workflow = Workflow(
        "workflow_name",
        vm,
        d,
        [
            Job(
                test_case_boot,
                [Job(test_case1_1, [Job(test_case1_1_1)]), Job(test_case1_2)],
            ),
            Job(test_case2),
        ],
    )

    # if run_failed:= True:
    # only run failed test
    workflow.load_result()

    workflow.run()

    workflow.save_result()

    print(workflow)

    d.stop()
    vm.stop()
