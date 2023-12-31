# 深入分析 os-autoinst

此文档尝试分析 os-autoinst 的底层逻辑, 目的在于为定制测试框架, (鉴于 openQA 的可维护性太差, 使用依然过于复杂) 提供一个前导性质的可行性分析, 及思路

但鉴于这是一个十年老库, 代码库复杂(或者对普通程序员说太不常见), 基于多进程架构, 以及 perl 语言及其生态, 难以阅读, 只能尽力

## 架构

官方完整示例: <https://open.qa/docs/images/architecture.svg>

### 模块

- isotovideo: 负责启动下面三个子进程, 处理消息转发, 停止等
- backend: 负责启动虚拟机, 连接 vnc, 串口等
- autotest: 负责运行测试脚本
- command server: 负责为 ui(live), worker 提供服务

### 进程树

- isotovideo: 生成其他进程，用于处理命令的 IO loop（主要），清理相关文件： isotovideo，needle.pm （初始 needle 扫描）
    - backend: 1. 生成并处理 backend（例如 qemu）2. 接收来自 isotovideo IO loop 的命令, 3. 处理 VNC 连接，制作常规屏幕截图相关文件： `baseclass.pm` 及其派生，`console.pm` 及其派生, needle.pm（用于 reloading 和 matching）, 还有 `cv.pm` 以及 `ppmclibs/*`
        - qemu (for instance)
        - videoencoder: 对 Ogg Theora 文件进行编码，相关文件：`videoencoder.cpp`
    - autotest: 确定测试顺序，运行测试代码，运行 testapi 函数，通过 query_isotovideo 将命令发送到 isotovideo IO loop. 相关文件： `autotest.pm`, `basetest.pm` 及其派生，`needle.pm`, `testapi.pm`, `console_proxy.pm`
    - command server: 提供 GET/POST HTTP 路由和 WS server，将通过 WS 接收到的命令传递给 isotovideo IO loop. 相关文件： `commands.pm`，`OpenQA/Commands.pm`

注意:

- isotovideo 启动所有内容并在其他进程之间传递命令。
- 除 autotest 外，所有进程都有一个 IO 循环。后者主要执行测试代码，其他一切都对它做出反应。
- `command server` 用于为 openQA worker 和 livehandler 提供服务

## 常用套路

以下为 os-autoinst 代码库常用的一些代码片段

### 多进程

创建了一个双向通道, child 进程关闭 `$child`, 使用 `$isotovideo` 与父进程通信

```perl
sub start_server ($port) {
    # 创建父子进程 fd
    my ($child, $isotovideo);
    # 此函数用于创建套接字, 关联父子进程, 但是和网络无关
    socketpair($child, $isotovideo, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
      or die "cmdsrv: socketpair: $!";

    # 简单 flash
    $child->autoflush(1);
    $isotovideo->autoflush(1);

    # 创建子进程
    my $process = Mojo::IOLoop::ReadWriteProcess(sub {
            # 处理信号量
            $SIG{TERM} = 'DEFAULT';
            $SIG{INT} = 'DEFAULT';
            $SIG{HUP} = 'DEFAULT';
            $SIG{CHLD} = 'DEFAULT';

            # 子进程关闭 `$child` 端
            close($child);
            $0 = "$0: commands";

            ### 启动主要程序
            run_daemon($port, $isotovideo);
            Devel::Cover::report() if Devel::Cover->can('report');
            _exit(0);
        },
        sleeptime_during_kill => 0.1,
        total_sleeptime_during_kill => 5,
        blocking_stop => 1,
        internal_pipes => 0,
        set_pipes => 0)->start;

    # 父进程关闭 $isotovideo 端
    close($isotovideo);

    # 当当子进程退出时，collected 事件将会被触发，并执行相应的回调函数
    $process->on(collected => sub { bmwqemu::diag("commands process exited: " . shift->exit_status); });

    # 返回子进程的句柄
    return ($process, $child);
}

```

### 多进程通信 / jsonRPC

其实就是 socket 通信, 指定一个 fd 即可, 发送和接受都是 json 格式, 由于都是 json, 自然也不需要 len 判断消息结束.

```perl
sub send_json ($to_fd, $cmd)
sub read_json ($socket, $cmd_token = undef, $multi = undef)
```

不同文件下会对这两个函数进一步封装, 把 fd 设置为需要的

### http 通信

访问由 isotovideo 启动的 http server:

```perl
testapi::autoinst_url("/current_script")

sub autoinst_url ($path = undef, $query = undef, $args = {}) {
    $path //= '';
    $query //= {};
    my $hostname = get_var('AUTOINST_URL_HOSTNAME', host_ip($args));
    # QEMUPORT is historical for the base port of the worker instance
    my $workerport = get_var("QEMUPORT") + 1;

    my $token = get_var('JOBTOKEN');
    my $querystring = join('&', map { "$_=$query->{$_}" } sort keys %$query);
    my $url = "http://$hostname:$workerport/$token$path";
    $url .= "?$querystring" if $querystring;

    return $url;
}
```

### 事件处理

`Mojo::EventEmitter` 是 Mojolicious 框架中用于处理事件的模块。基本使用方法：

```perl
# 引入 Mojo::EventEmitter 模块
use Mojo::EventEmitter;

# 创建一个 Mojo::EventEmitter 对象：
my $emitter = Mojo::EventEmitter->new();

# 添加事件处理器
$emitter->on('some_event', sub {
    my ($emitter, @args) = @_;
    say "Received event 'some_event' with args: @args";
});

# 触发事件
$emitter->emit('some_event', 'arg1', 'arg2');
```

### query_isotovideo

把输入转换为:

```js
{
    ...$args
    cmd: $cmd,
}
```

发送给 isotovideo

```perl
sub query_isotovideo ($cmd, $args = undef) {
    # deep copy
    my %json;
    if ($args) {
        %json = %$args;
    }
    $json{cmd} = $cmd;

    die "isotovideo is not initialized. Ensure that you only call test API functions from test modules, not schedule code\n" unless defined $isotovideo;
    myjsonrpc::send_json($isotovideo, \%json);

    # wait for response (if test is paused, this will block until resume)
    my $rsp = myjsonrpc::read_json($isotovideo);

    return $rsp->{ret};
}
```

### 路由命名空间

一下面这段代码为例简单介绍 Mojo 路由命名空间用法:

```perl
my $r = app->routes;
$r->namespaces(['OpenQA']);
my $token_auth = $r->any("/$bmwqemu::vars{JOBTOKEN}");
$token_auth->websocket('/ws')->name('ws')->to('commands#start_ws');
```

namespaces 可以指定命名空间, 后续的 handler, 例如 `to('commands#start_ws')` 就会调用 `OpenQA::commands::start_ws` 函数

## 独立模块

### TODO tinycv

## cosole 模块

console 被定义为终端, 可以是 vnc 也可以是 ssh, 串口等任何终端. 一个 backend 可以有多个 console.

分别用于基于图片, 输出的测试断言

### 初始化

`$testapi::distri->add_console`

```perl
# 翻译一下参数就是        name,             type             args
sub add_console ($self, $testapi_console, $backend_console, $backend_args = undef) {
    # type => class
    my %class_names = (
        'tty-console' => 'ttyConsole',
        'ssh-serial' => 'sshSerial',
        'ssh-xterm' => 'sshXtermVt',
        'ssh-virtsh' => 'sshVirtsh',
        'ssh-virtsh-serial' => 'sshVirtshSUT',
        'vnc-base' => 'vnc_base',
        'local-Xvnc' => 'localXvnc',
        'ssh-iucvconn' => 'sshIucvconn',
        'virtio-terminal' => 'virtio_terminal',
        'amt-sol' => 'amtSol',
        'ipmi-sol' => 'ipmiSol',
        'ipmi-xterm' => 'sshXtermIPMI',
        'video-stream' => 'video_stream',
    );
    my $required_type = $class_names{$backend_console} || $backend_console;
    my $location = "consoles/$required_type.pm";
    my $class = "consoles::$required_type";

    require $location;

    # 按照类型实例化一个 console, 获取 socket 对象, 后续可以通过 socket 与 vnc 交互
    my $ret = $class->new($testapi_console, $backend_args);
    # 使用 hash 存储到 distri 类里
    $self->{consoles}->{$testapi_console} = $ret;
    return $ret;
}
```

### select_console

```perl
# testapi(autotest)
sub select_console ($testapi_console, @args) {
    # 为 console 添加一层代理, 不直接访问
    if (!exists $testapi_console_proxies{$testapi_console}) {
        $testapi_console_proxies{$testapi_console} = backend::console_proxy->new($testapi_console);
    }
    # 由 backend 调用, 这里会再转发回 backend, 调用 backend 的 select_console 函数
    my $ret = query_isotovideo('backend_select_console', {testapi_console => $testapi_console});
    die $ret->{error} if $ret->{error};

    # 设置 autotest 后续交互的对象, 例如 send_text, send_key, wait_screen_change
    # TODO: 使用例子:autotest 什么时候需要用 console
    $autotest::selected_console = $testapi_console;

    ...

    return $testapi_console_proxies{$testapi_console};
}
```

### vnc_base

对于 vnc 来说, 在初始化过程中, `my $ret = $class->new($testapi_console, $backend_args);` 通过 login 获取 socket 对象

os-autoinst 依赖通过 socket 向 VNC server 发送数据包, os-autoinst 自己零散的实现了部分 RDP 协议, 比如发送一个按键:

```perl
sub send_key_event ($self, $key, $press_release_delay) {
    $self->{vnc}->map_and_send_key($key, undef, $press_release_delay);
}

# map_and_send_key 会分别调用 key_down 和 key_up, 通过下面的函数发送两次数据

sub _send_key_event ($self, $down_flag, $key) {
    my $socket = $self->socket;
    my $template = 'CCnN';
    # for a strange reason ikvm has a lot more padding
    $template = 'CxCnNx9' if $self->ikvm;
    $socket->print(
        pack(
            $template,
            4,    # message_type
            $down_flag,    # down-flag
            0,    # padding
            $key,    # key
        ));
}
```

关于数据报的定义见下面文档:

VNC Protocal SPEC: https://github.com/rfbproto/rfbproto/blob/master/rfbproto.rst#keyevent

### video stream

video_stream 依赖于 ffmpeg 和 v4l2-cli, 会拼接如下的语句:

```bash
# 此处的 url 可以是
    # if ($args->{url} =~ m/^\/dev\/video/) {
ffmpeg -loglevel fatal -i <url> -vcodec ppm -f rawvideo -r 2 -
```

通过子进程的方式运行上面的代码.

后续可以通过返回的 fd 读取 header, body 的方式读取每一帧, 交给 tinycv 处理成图片, 缓存到 _framebuffer

此 console 在 os-autoinst 代码中也可以发送键盘事件, 但是是通过特殊硬件模拟实现的(USB 键盘), 这里不做进一步研究

### serial


## 分解流程

### 配置文件

```json
{
   "DISTRI" :      "opensuse",
   "CASEDIR" :     "/full/path/for/tests",
   "NAME" :        "test-name",
   "ISO" :         "/full/path/for/iso",
   "VNC" :         "91",
   "BACKEND" :     "qemu",
   "DESKTOP" :     "kde"
}
```

### isovideo 启动

入口文件 _isotovideo_

```perl
eval {
    # 准备阶段
    $runner = OpenQA::Isotovideo::Runner->new;
    # 子进程 0 [main IO loop]
    $runner->prepare;

    # 子进程 1 [autotest]
    $runner->start_autotest;
    # 子进程 2 [backend]
    $runner->create_backend;
    # 子进程 3 [command server]
    $runner->handle_commands;

    # 运行主循环, 从 autotest, command server and backend 接受信息并处理
    $runner->run;

    # 终止 command server, 并提前通知与其连接的 websocket 客户端
    $runner->stop_commands('test execution ended');
    my $clean_shutdown = $runner->handle_shutdown(\$return_code);

    # 处理需要上传到 <TODO> 的资源文件
    bmwqemu::load_vars();
    $return_code = handle_generated_assets($runner->command_handler, $clean_shutdown) unless $return_code;
};
```

### prepare 阶段

```perl
# OpenQA/Isotovideo/Runner.pm
sub prepare ($self) {
    # 1. 清空标准输入输出
    $self->_flush_std;
    # 2. 检查环境变量 CASEDIR, PRODUCTDIR, NEEDLES_DIR 是否存在
    $self->checkout_code;
    # 3. 加载测试文件
    $self->load_schedule;
    # 4. 启动子进程
    $self->start_server;
    # 5. 初始化 testapi, `$serialdev = ttyS0`
    testapi::init();
    # 6. 配置 needle 文件夹
    needle::init();
}
```

第三步 load_schedule: 可以从 main.pm 或者 SCHEDULE 加载测试文件

1. 通过 require 直接加载一个 main.pm 文件会直接使用 `require main.pm` 语句运行 `main.pm` (得益于脚本语言). `main.pm` 中应该由用户使用 `autotest::load_test` 主动加载配置文件
2. 加载 SCHEDULE 变量, 调用 `autotest::load_test` 函数加载测试文件

> 这里的 load_test 函数把测试文件推到数组中 `@testorder`, 具体流程见下文 [TODO 设置锚点]

第四步 start_server 是最重要的一步: 这里启动了一个子进程, 分别运行一个 http server 和一个 IO loop

1. http server 接受到的大部分请求会被 handler 直接处理
2. IO loop 会把该请求广播到所有 clients(指 webui):
3. 特殊的 `/isotovideo/#command` 接口的 handler 会通过 `myjsonrpc::send_json` 把请求转发到 IO loop 处理(即广播到 clients)

> 注意: command server 只用于和 webui worker 交互, 对于 os-autoinst 本身并没有用处

```perl
# api
myjsonrpc::send_json($isotovideo, {cmd => $cmd, params => $mojo_lite_controller->req->query_params->to_hash});

# IO loop
my @isotovideo_responses = myjsonrpc::read_json($isotovideo, undef, 1);
my $clients = app->defaults('clients');
for my $response (@isotovideo_responses) {
    _handle_isotovideo_response(app, $response);
    for (keys %$clients) {
        $clients->{$_}->send({json => $response});
    }
}
```

所有接口如下:

```perl
app->defaults(isotovideo => $isotovideo);
app->defaults(clients => {});

my $r = app->routes;
$r->namespaces(['OpenQA']);

# 所有接口都需要 token
my $token_auth = $r->any("/$bmwqemu::vars{JOBTOKEN}");

# 1. 文件相关接口
# for access all data as CPIO archive
$token_auth->get('/data' => \&test_data);
# to access a single file or a subdirectory
$token_auth->get('/data/*relpath' => \&test_data);
# uploading log files from tests
$token_auth->post('/uploadlog/#filename' => {target => 'ulogs'} => [target => [qw(ulogs)]] => \&upload_file);
# uploading assets
$token_auth->post('/upload_asset/#filename' => [target => [qw(assets_private assets_public)]] => \&upload_file);

# 2. 当前脚本
# to get the current bash script out of the test
$token_auth->get('/current_script' => \&current_script);

# 3. 当前 server 临时文件
# to get temporary files from the current worker
$token_auth->get('/files/*relpath' => \&get_temp_file);

# 4. 资源文件
# get asset
$token_auth->get('/assets/#assettype/#assetname' => \&get_asset);
$token_auth->get('/assets/#assettype/#assetname/*relpath' => \&get_asset);

# 5. 环境变量(为了方便可以在不同服务间传播)
# get vars
$token_auth->get('/vars' => \&get_vars);

# 6. isotovideo
$token_auth->get('/isotovideo/#command' => \&isotovideo_get);
$token_auth->post('/isotovideo/#command' => \&isotovideo_post);

# 7. websocket 服务
# websocket related routes
$token_auth->websocket('/ws')->name('ws')->to('commands#start_ws');
$token_auth->post('/broadcast')->name('broadcast')->to('commands#broadcast_message_to_websocket_clients');

# not known by default mojolicious
app->types->type(oga => 'audio/ogg');

# it's unlikely that we will ever use cookies, but we need a secret to shut up mojo
app->secrets([$bmwqemu::vars{JOBTOKEN}]);

# listen to all IPv4 and IPv6 interfaces (if ipv6 is supported)
my $address = '[::]';
if (!IO::Socket::IP->new(Listen => 5, LocalAddr => $address)) {
    $address = '0.0.0.0';
}
my $daemon = Mojo::Server::Daemon->new(app => app, listen => ["http://$address:$port"]);
```

### start_autotest

首先依然是按照上面的套路创建一个子进程, 返回 `return ($process, $child);`

在子进程内完成的工作:

1. 加载图像处理库 tinycv(利用 ffi), 并初始化(创建执行线程)
2. 运行所有测试

#### 运行测试

检查是否支持快照:

```perl
    my $snapshots_supported = query_isotovideo('backend_can_handle', {function => 'snapshots'});

```

测试循环(_autotest.pm:380_):

```perl
for (my $testindex = 0; $testindex <= $#testorder; $testindex++) {
    my $t = $testorder[$testindex];

    # 设置运行标志
    $t->start();

    # 真正运行测试
    eval { $t->runtest; };

    # 处理错误
    my $error = $@;    # save $@, it might be overwritten
    if ($error) {
        ...
    } else {
        # 可选: 回滚, 制作快照, ...
    }
    # 保存运行结果
    $t->save_test_result();
}
```

运行测试脚本(_basetest.pm:339_):

```perl

sub runtest ($self) {
    # 计时
    $self->{test_start_time} = time;

    my ($died, $error_message, $ignore_error);
    my $name = $self->{name};
    # Set flags to the field value
    $self->{flags} = $self->test_flags();

    # 执行测试脚本的 pre_run_hook, run, post_run_hook
    eval {
        $self->pre_run_hook();
        if (defined $self->{run_args}) {
            $self->run($self->{run_args});
        }
        else {
            $self->run();
        }
        $self->post_run_hook();
    };

    # 错误处理
    if ($error_message = $@) {
        ...
    }

    # 处理 qemu 输出
    eval { $self->search_for_expected_serial_failures(); };
    # Process serial detection failure
    if ($@) {
        bmwqemu::diag($error_message = $@);
        $self->record_resultfile('Failed', $@, result => 'fail');
        $died = 1;
    }

    # 统计时间
    $self->compute_test_execution_time();

    # 设置状态
    $self->done();
    return;
}
```

```perl
sub done ($self) {
    $self->{running} = 0;
    $self->{result} ||= 'ok';
    unless ($self->{test_count}) {
        $self->take_screenshot();
    }
    autotest::set_current_test(undef);
}
```

### create_backend

根据 BACKEND 变量创建对应的类, 启动 VM

```perl

sub new ($class, @args) {
    # 默认使用 qemu
    $bmwqemu::vars{BACKEND} ||= "qemu";
    # 实例化
    $bmwqemu::backend = backend::driver->new($bmwqemu::vars{BACKEND});

        # 下面函数来自 backend/driver.pm
        sub new ($class, $name) {
            my $self = $class->SUPER::new({class => $class});

            # 动态加载对应 backend 文件
            require "backend/$name.pm";
            # 实例化 (创建 qemu.pid )
            $self->{backend} = "backend::$name"->new();
            $self->{backend_name} = $name;
            session->on(collected_orphan => \&_collect_orphan);

            # 启动一个子进程, 调用 baseclass 的 run 方法:
            # 设置 console->backend, 运行 run_capture_loop
            $self->start();
            return $self;
        }

    # 创建一个文件，写入当前进程 pid
    path('os-autoinst.pid')->spew("$$");
    # 真正启动机器的地方
    $bmwqemu::backend->start_vm;
    $class->SUPER::new(@args);
}
```

下面详细介绍 `start()` 和 `start_vm()`

#### start

start 函数创建一个子进程, 核心步骤如下

```perl
sub start ($self) {
    open(my $STDOUTPARENT, '>&', *STDOUT);
    open(my $STDERRPARENT, '>&', *STDERR);

    my $backend_process = process(
        code => sub {
            my $process = shift;
            $0 = "$0: backend";

            open STDOUT, ">&", $STDOUTPARENT;
            open STDERR, ">&", $STDERRPARENT;

            # 初始化 OpenCV
            my $signal_blocker = signalblocker->new;
            require cv;
            cv::init();
            require tinycv;
            tinycv::create_threads();
            undef $signal_blocker;

            # 启动 qemu.pm
            $self->{backend}->run(fileno($process->channel_in), fileno($process->channel_out));
        });

    $backend_process->start;

    $self->{backend_pid} = $backend_process->pid;
    $self->{backend_process} = $backend_process;
}
```

这里的 `$self->{backend}->run` 会运行 backend 的 run 方法, 该方法的主要功能是启动 capture_loop (注意此时虚拟机尚未启动), 并通过 channel_in 和 channel_out 通道进行输入和输出交互.

run 方法包含在 `backend/baseclass.pm`:

```perl
# backend/baseclass.pm
sub run ($self, $cmdpipe, $rsppipe) {
    $backend = $self;

    my $io = IO::Handle->new()->fdopen($cmdpipe, "r")
    $self->{cmdpipe} = $io;

    $io = IO::Handle->new()->fdopen($rsppipe, "w");
    $self->{rsppipe} = $io;

    my $select_read = $self->{select_read} = OpenQA::NamedIOSelect->new;
    my $select_write = $self->{select_write} = OpenQA::NamedIOSelect->new;

    # 使用 select 技术, 添加感兴趣的 fd
    $select_read->add($self->{cmdpipe}, "baseclass::cmdpipe");
    $select_write->add($self->{cmdpipe}, "baseclass::cmdpipe");

    # 一些默认值
    $self->last_update_request("-Inf" + 0);
    $self->last_screenshot(undef);
    $self->screenshot_interval($bmwqemu::vars{SCREENSHOTINTERVAL} || .5);
    # query the VNC backend more often than we write out screenshots, so the chances
    # are high we're not writing out outdated screens
    $self->update_request_interval($self->screenshot_interval / 2);

    # 为 console 添加 backend 的引用, 关于 console 的介绍 <TODO:>
    for my $console (values %{$testapi::distri->{consoles}}) {
        # tell the consoles who they need to talk to (in this thread)
        $console->backend($self);
    }

    # 核心函数, 启动拍照循环
    $self->run_capture_loop;

    bmwqemu::diag("management process exit at " . POSIX::strftime("%F %T", gmtime));
}

```

#### capture_loop(command_handler)

1. run_capture_loop 会调用 console 的 capture_screenshot 方法捕获屏幕,
2. 同时也是负责接受, 执行 command 的地方, 通过 select 机制, 从 cmdpipe 读取 cmd, **并调用同名方法**

下面时 do_capture 的大体框架, 关于 assert_screen 实现等详细内容见 testapi 章节

```perl
# backend/baseclass.pm
sub run_capture_loop ($self, $timeout = undef) {
    ...
    my $starttime = gettimeofday;
    eval { $self->do_capture($timeout, $starttime) };
    ...
}

# backend/baseclass.pm
sub do_capture ($self, $timeout = undef, $starttime = undef) {
    # Time slot buckets
    my $buckets = {};
    my $wait_time_limit = $bmwqemu::vars{_CHKSEL_RATE_WAIT_TIME} // 30;
    my $hits_limit = $bmwqemu::vars{_CHKSEL_RATE_HITS} // 30_000;

    while (1) {
        # 只有当 cmdpipe 建立之后才进行后续逻辑
        last unless $self->{cmdpipe};

        ...

        # 捕获屏幕, 如果到达超时时间
        my $screenshot_interval = min($self->screenshot_interval, @additional_intervals);
        my $time_to_screenshot = $screenshot_interval - ($now - $self->last_screenshot);
        if ($time_to_screenshot <= 0) {
            # 具体实现参考关键原理一节
            # 总之捕获到的图片会保存在名为 $self->last_image, 供 assert_screen 等使用
            $self->capture_screenshot();
            $self->last_screenshot($now);
            $time_to_screenshot = $screenshot_interval;
        }

        # 对比屏幕是否更新: 见 <TODO: 设置锚点>, b把对比结果发送到 rsppipe
        $self->_check_for_screen_change($now) or $self->_check_for_still_screen($now);

        # 更新各种状态
        ...

        # 启动 select, 处理来自 isotovideo 的请求
        my ($read_set, $write_set) = IO::Select->select($self->{select_read}->select(), $self->{select_write}->select(), undef, $time_to_next);
        for my $fh (@$read_set) {
            $self->check_socket($fh, 0);
            last;
        }
    }
}
```

#### start_vm

start_vm 函数:

```perl
sub start_vm ($self) {
    my $json = to_json({backend => $self->{backend_name}});
    open(my $runf, ">", 'backend.run');
    print $runf "$json\n";
    close $runf;

    # remove old screenshots
    remove_tree($bmwqemu::screenshotpath);
    mkdir $bmwqemu::screenshotpath;

    $self->_send_json({cmd => 'start_vm'}) || die "failed to start VM";
    return 1;
}
```

当上述 backend_process 启动之后, start_vm 会通过 `_send_json` 向 backend 发送 jsonRPC(`cmd = start_vm`), 使 backend_process 调用 `baseclass.pm` 的 `start_vm` 方法, 最后调用具体 `backend` 实现的 `do_start_vm` 方法, 真正启动 backend.

当 backend 启动之后就是不可控的了, 只有测试脚本的运行是可控的, 用户也只能通过在 webui 向 BackendHandler 发出请求控制测试脚本暂停等

### handle_commands

new 了一个 CommandHandler 对象, 该对象引入了 `Mojo::EventEmitter`, 因此可以作为事件处理器, 处理来自 http 的请求, 一般都是由 webui 或 worker 发出, 与 isotovideo 自身执行基本无关, 下面是基本框架:

```perl
sub handle_commands ($self) {
    my $command_handler;
    # stop main loop as soon as one of the child processes terminates
    my $stop_loop = sub (@) { $self->loop(0) if $self->loop; };
    # 在任意子进程结束后都会调用 $stop_loop 函数将 loop 设置为 0 表示结束
    $self->testprocess->once(collected => $stop_loop);
    $self->backend->process->once(collected => $stop_loop);
    $self->cmd_srv_process->once(collected => $stop_loop);

    # 初始化 CommandHandler
    $command_handler = OpenQA::Isotovideo::CommandHandler->new(
        cmd_srv_fd => $self->cmd_srv_fd,
        test_fd => $self->testfd,
        backend_fd => $self->backend->process->channel_in,
        backend_out_fd => $self->backend->process->channel_out,
    );

    # 设置了一个 tests_done 事件, 接收到事件后, 停止各个系统
    $command_handler->on(tests_done => sub (@) {
            CORE::close($self->testfd);
            $self->testfd(undef);
            $self->stop_autotest();
            $self->loop(0);
    });

    # 设置回调, 还是停止相关
    $command_handler->on(signal => sub ($event, $sig) {
            $self->backend->stop if defined $self->backend;
            $self->stop_commands("received signal $sig");
            $self->stop_autotest();
            _exit(1);
    });
    # 设置信号处理器, 转发, 触发上面的回调
    $self->setup_signal_handler;

    $self->command_handler($command_handler);
}

# 设置信号处理器
sub setup_signal_handler ($self) {
    my $signal_handler = sub ($sig) { $self->_signal_handler($sig) };
    $SIG{TERM} = $signal_handler;
    $SIG{INT} = $signal_handler;
    $SIG{HUP} = $signal_handler;
}

# 触发上面的回调
sub _signal_handler ($self, $sig) {
    bmwqemu::serialize_state(component => 'isotovideo', msg => "isotovideo received signal $sig", log => 1);
    return $self->loop(0) if $self->loop;
    $self->command_handler->emit(signal => $sig);
}
```

### run

runner 负责从 autotest fd, backend out_channel, cmd_server(初始化自 prepare 阶段, api server) fd 接受消息, 将消息发送到 backend 或者 直接调用

例如许多有测试脚本即 autotest 调用的 testapi 就依赖 isotovideo 把命令转发到 backend

```perl
sub run ($self) {
    # now we have everything, give the tests a go
    $self->testfd->write("GO\n");

    my $ch = $self->command_handler;
    my $io_select = IO::Select->new();
    $io_select->add($self->testfd);
    $io_select->add($ch->cmd_srv_fd);
    $io_select->add($ch->backend_out_fd);

    while ($self->loop) {
        my ($ready_for_read, $ready_for_write, $exceptions) = IO::Select::select($io_select, undef, $io_select, $ch->timeout);
        for my $readable (@$ready_for_read) {
            my $rsp = myjsonrpc::read_json($readable);
            $self->_read_response($rsp, $readable);
            last unless defined $rsp;
        }
        $ch->check_asserted_screen if defined($ch->tags);
    }
    $ch->stop_command_processing;
    return 0;
}
```

_read_response 不只是读取消息

```perl
sub _read_response ($self, $rsp, $fd) {
    ...
    if ($fd == $self->command_handler->backend_out_fd) {
        # 如果是来自 backend_out 的消息, 转发给请求者 <TODO: requester 的注册>
        $self->command_handler->send_to_backend_requester({ret => $rsp->{rsp}});
    } else {
        # 其他消息, 来自 command server 和 autotest 都直接处理
        $self->command_handler->process_command($fd, $rsp);
    }
}
```

```perl
sub process_command ($self, $answer_fd, $command_to_process) {
    my $cmd = $command_to_process->{cmd} or die 'isotovideo: no command specified';
    $self->answer_fd($answer_fd);

    # 调用的方法为: `_handle_command_${rsp->{cmd}}`
    if (my $handler = $self->can('_handle_command_' . $cmd)) {
        return $handler->($self, $command_to_process, $cmd);
    }
    # 或者传递给 backend, 调用 `$1`
    if ($cmd =~ m/^backend_(.*)/) {
        return $self->_pass_command_to_backend_unless_paused($command_to_process, $1);
    }
    die 'isotovideo: unknown command ' . $cmd;
}

```

下面是支持的 command 列表

```perl
# 用于 webui 操作
sub _handle_command_report_timeout ($self, $response, @)
sub _handle_command_is_configured_to_pause_on_timeout ($self, $response, @)
sub _handle_command_set_pause_at_test ($self, $response, @)
sub _handle_command_set_pause_on_screen_mismatch ($self, $response, @)
sub _handle_command_set_pause_on_next_command ($self, $response, @)
sub _handle_command_set_pause_on_failure ($self, $response, @)
sub _handle_command_pause_test_execution ($self, $response, @)
sub _handle_command_resume_test_execution ($self, $response, @)
sub _handle_command_set_current_test ($self, $response, @)

# 测试运行结束
sub _handle_command_tests_done ($self, $response, @)
# 屏幕比对
sub _handle_command_check_screen ($self, $response, @)

sub _handle_command_set_assert_screen_timeout ($self, $response, @)
sub _handle_command_status ($self, $response, @)
sub _handle_command_version ($self, $response, @)
sub _handle_command_read_serial ($self, $response, @)
sub _handle_command_send_clients ($self, $response, @)
```

## backend 实现

### generalhw

```perl
sub do_start_vm ($self, @) {
    $self->truncate_serial_file;
    # 刷入镜像
    if ($bmwqemu::vars{GENERAL_HW_FLASH_CMD}) {
        # Append HDD infos to flash script
        my $hdd_args = $self->compute_hdd_args;

        $self->poweroff_host;    # Ensure system is off, before flashing
        $self->run_cmd('GENERAL_HW_FLASH_CMD', @$hdd_args);
    }
    # 只是调用用户传入的重启脚本
    $self->restart_host;

    # 创建一个 vnc 对象, 后续 backend 和 vnc 交互依赖于返回的 socket
    # new 一个 console, 并调用 select_console 添加到 $testapi::distri 并 设置 $self->consoles
    $self->relogin_vnc if ($bmwqemu::vars{GENERAL_HW_VNC_IP});
        sub relogin_vnc ($self) {
            if ($self->{vnc}) {
                close($self->{vnc}->socket);
                sleep(1);
            }

            my $vnc = $testapi::distri->add_console(
                'sut',
                'vnc-base', # 类型
                {
                    hostname => $bmwqemu::vars{GENERAL_HW_VNC_IP} || die('Need variable GENERAL_HW_VNC_IP'),
                    port => $bmwqemu::vars{GENERAL_HW_VNC_PORT} // 5900,
                    password => $bmwqemu::vars{GENERAL_HW_VNC_PASSWORD},
                    depth => $bmwqemu::vars{GENERAL_HW_VNC_DEPTH} // 16,
                    connect_timeout => 50
                });
            $vnc->backend($self);
            $self->select_console({testapi_console => 'sut'});

            return 1;
        }

    # 另一个 video 获取方式, 依赖测试机器环境有 ffmpeg 和 v4l2
    $self->reconnect_video_stream if ($bmwqemu::vars{GENERAL_HW_VIDEO_STREAM_URL});
        sub reconnect_video_stream ($self, @) {

            my $input_cmd;
            $input_cmd = $self->get_cmd('GENERAL_HW_INPUT_CMD') if ($bmwqemu::vars{GENERAL_HW_INPUT_CMD});
            my $vnc = $testapi::distri->add_console(
                'sut',
                'video-stream', # 类型
                {
                    url => $bmwqemu::vars{GENERAL_HW_VIDEO_STREAM_URL},
                    connect_timeout => 50,
                    input_cmd => $input_cmd,
                    edid => $bmwqemu::vars{GENERAL_HW_EDID},
                });
            $vnc->backend($self);
            $self->select_console({testapi_console => 'sut'});

            return 1;
        }

    # 启动一个子进程来执行串口数据的抓取工作。
    $self->start_serial_grab if (($bmwqemu::vars{GENERAL_HW_VNC_IP} || $bmwqemu::vars{GENERAL_HW_SOL_CMD}) && !$bmwqemu::vars{GENERAL_HW_NO_SERIAL});
        sub start_serial_grab ($self) {
            $self->{serialpid} = fork();
            return unless $self->{serialpid} == 0;
            setpgrp 0, 0;
            # 打开一个文件句柄 $serial，并将其关联到 $self->{serialfile} 指定的文件中。将子进程的输出重定向到该文件。
            open(my $serial, '>', $self->{serialfile});
            open(STDOUT, ">&", $serial);
            open(STDERR, ">&", $serial);
            # 调用用户编写的串口抓取脚本, 特定于某机器
            exec($self->get_cmd('GENERAL_HW_SOL_CMD'));
            die "exec failed $!";
        }

    return {};
}
```

### qemu

```perl
```

## 状态流转

状态/动作/消息/事件流转

### 数据结构图

```rust
isotovideo: isotovideo {
    runner: Runner {
        // command server 子进程
        cmd_srv_process: process {
            run() {
                app(url, c)
                ioloop($isotovideo) {
                }
            }
        }
        cmd_srv_fd: fd
        cmd_srv_port: int


        // autotest 子进程
        testprocess: {
            run() {
                run_all () {
                    // 整体 state
                    died = 0;
                    completed = 0;
                    tests_running = 1;

                    completed = runalltests() {

                    }()
                    current_test
                }
            }
        }
        testfd: fd

        // backend 空壳
        // Backend 只是个空壳, 会调用下方函数, 初始化 bmwqemu.driver:
        // $bmwqemu::backend = backend::driver->new();
        // $bmwqemu::backend->start_vm;
        backend: Backend

        command_handler: CommandHandler {
            (cmd_srv_fd, test_fd, backend_fd, backend_out_fd)
        }
    }

    autotest {
        testorder: []test
    }

    bmwqemu {
        driver: backend::driver {
            backend: backend::$name
            backend_name: $name
            // backend 子进程
            backend_process: process {
                channel_out
                channel_in
                run() {
                    // 即为 backend::$name::run
                    $self->{backend}->run(fileno($process->channel_in), fileno($process->channel_out));
                }
            }
            backend_pid: pid
        }
    }
}
```

<!-- ### 启动同步 -->
<!-- ### 运行时反馈 -->

### 停止同步

## testapi 实现

### python 语言支持

```py
# publish all test API methods over perl into the modules context.
# Use with `import testapi; testapi.method()` or `from testapi import *`
import perl

perl.use("testapi")
for i in dir(perl.testapi):
    locals()[i] = getattr(perl.testapi, i)

```

### assert_screen

testapi 相关代码:

```perl
sub assert_screen {    # no:style:signatures
    my ($mustmatch) = shift;
    my $timeout = shift if (@_ % 2);
    my %args = (timeout => $timeout // $bmwqemu::default_timeout, @_);
    # 只是对 _check_or_assert 的简单包装
    return _check_or_assert($mustmatch, 0, %args);
}
```

`_check_or_assert` 实现:

```perl
sub _check_or_assert ($mustmatch, $check, %args) {
    die "no tags specified" if (!$mustmatch || (ref $mustmatch eq 'ARRAY' && scalar @$mustmatch == 0));
    die "current_test undefined" unless $autotest::current_test;

    $args{timeout} = bmwqemu::scale_timeout($args{timeout});

    # 注意循环
    while (1) {
        # 向 isotovideo 发出请求, query_isotovideo 转发到 clients, TODO: clients 的注册
        my $rsp = query_isotovideo('check_screen', {mustmatch => $mustmatch, check => $check, timeout => $args{timeout}, no_wait => $args{no_wait}});

        # 检查 backend 反馈(可能递归调用)
        my $backend_response = _check_backend_response($rsp, $check, $args{timeout}, $mustmatch);
        ...
    }
}
```

`query_isotovideo('check_screen',` 方法会发请求到 iostovideo, 在分发到 `_handle_command_check_screen` 函数

```perl
sub _handle_command_check_screen ($self, $response, @) {
    $self->no_wait($response->{no_wait} // 0);
    # 如果用户在 webui 页面设置了 pause, 这个函数会修改状态文件
    return if $self->_postpone_backend_command_until_resumed($response);

    my %arguments = (
        mustmatch => $response->{mustmatch},
        timeout => $response->{timeout},
        check => $response->{check},
    );
    my $current_api_function = $response->{check} ? 'check_screen' : 'assert_screen';
    $self->_send_to_cmd_srv({
            check_screen => \%arguments,
            current_api_function => $current_api_function,
    });
    # 向 backend 发出请求(从 channel_in 发送 json, 从 channel_out 读取返回值)
    # 这里的 tag
    $self->tags($bmwqemu::backend->_send_json(
            {
                cmd => 'set_tags_to_assert',
                arguments => \%arguments,
            })->{tags});
    # 修改一个名为 current_api_function 的成员
    $self->current_api_function($current_api_function);
}
```

下面是 backend 测对应的处理函数

```perl
sub set_tags_to_assert ($self, $args) {
    my $mustmatch = $args->{mustmatch};
    my $timeout = $args->{timeout} // $bmwqemu::default_timeout;

    ...

    my $needles = needle::tags($mustmatch) || [];
    my @tags = ($mustmatch);

    $mustmatch = join(',', @tags);
    bmwqemu::fctinfo "NO matching needles for $mustmatch" unless @$needles;

    # 设置一系列变量, 这些变量会在 do_capture loop 中得到触发
    $self->set_assert_screen_timeout($timeout);
    $self->assert_screen_fails([]);
    $self->assert_screen_needles($needles);
    $self->assert_screen_last_check(undef);
    $self->stall_detected(0);
    $self->assert_screen_tags(\@tags);
    $self->assert_screen_check($args->{check});
    return {tags => \@tags};
}
```

但是上面的函数依然不会真正调用比较屏幕, 我们需要再次回到 runner 的 run 方法

当 runner 收到 backend 返回值之后, 如果返回值中包含 tags 字段, 则会再次向 backend 发起请求. 这次调用的是 `check_asserted_screen` 方法(不附带参数):

```perl

sub check_asserted_screen ($self, $args) {
    # 待检查的图像
    return unless my $img = $self->last_image;    # no screenshot yet to search on
    # 方便的打点计时器
    my $watch = OpenQA::Benchmark::Stopwatch->new();
    my $timestamp = $self->last_screenshot;
    # 超时时间
    my $n = $self->_time_to_assert_screen_deadline;
    # video frame 会在 capture loop 不断积累
    my $frame = $self->{video_frame_number};

    # do a full-screen search every FULL_SCREEN_SEARCH_FREQUENCY'th time and at the end
    # 图片比较的间隔时间
    my $search_ratio = $n < 0 || $n % FULL_SCREEN_SEARCH_FREQUENCY == 0 ? 1 : 0.02;
    my ($oldimg, $old_search_ratio) = @{$self->assert_screen_last_check || [undef, 0]};

    bmwqemu::diag('no change: ' . time_remaining_str($n)) and return if $n >= 0 && $oldimg && $oldimg eq $img && $old_search_ratio >= $search_ratio;

    $watch->start();
    $watch->{debug} = 0;

    # 过滤一下 needle
    my @registered_needles = grep { !$_->{unregistered} } @{$self->assert_screen_needles};
    # 调用 tinycv 查找最匹配的 needle
    my ($foundneedle, $failed_candidates) = $img->search(\@registered_needles, 0, $search_ratio, ($watch->{debug} ? $watch : undef));
    $watch->lap("Needle search") unless $watch->{debug};
    if ($foundneedle) {
        $self->_reset_asserted_screen_check_variables;
        return {
            image => encode_base64($img->ppm_data),
            found => $foundneedle,
            candidates => $failed_candidates,
            frame => $frame,
        };
    }

    # 没有找到匹配 needle 的后续处理
    $watch->stop();
    if ($watch->as_data()->{total_time} > $self->screenshot_interval) {
        bmwqemu::fctwarn sprintf(
            "check_asserted_screen took %.2f seconds for %d candidate needles - make your needles more specific",
            $watch->as_data()->{total_time},
            scalar(@registered_needles));
        bmwqemu::diag "DEBUG_IO: \n" . $watch->summary() if (!$bmwqemu::vars{NO_DEBUG_IO} && $watch->{debug});
    }

    ...
}
```

### send_key / mouse_set

```perl
sub send_key ($self, $args) {
    return $self->bouncer('send_key', $args);
}

sub bouncer ($self, $call, $args) {
    # forward to the current VNC console
    return unless $self->{current_screen};
    return $self->{current_screen}->$call($args);
}
```

依赖 current_screen 的 send_key 实现, 向 vnc 发送符合 rdp protocol 的数据包:

```perl
sub _send_key_event ($self, $down_flag, $key) {
    my $socket = $self->socket;
    my $template = 'CCnN';
    # for a strange reason ikvm has a lot more padding
    $template = 'CxCnNx9' if $self->ikvm;
    $socket->print(
        pack(
            $template,
            4,    # message_type
            $down_flag,    # down-flag
            0,    # padding
            $key,    # key
        ));
}
```

mouse_set 一样

### wait_serial



### script_run

基本上是 type_string 与 wait_serial 的组合, 此函数会在用户指定 cmd 的后面拼接一条 echo 语句:

```perl
testapi::type_string "$cmd";

my $marker = "; echo $str-\$?-" . ($args{output} ? "Comment: $args{output}" : '');

# 对于串口设备, 一切正常
if (testapi::is_serial_terminal) {
    testapi::type_string($marker);
    testapi::wait_serial($cmd . $marker, no_regex => 1, quiet => $args{quiet});
    testapi::type_string("\n");
} else {
    # 对于其他设备, 例如 vnc 还是会把 marker 打印到串口
    testapi::type_string "$marker > /dev/$testapi::serialdev\n";
}

my $res = testapi::wait_serial(qr/$str-\d+-/, timeout => $args{timeout}, quiet => $args{quiet});
```

## 关键原理

### 与 VNC 交互

参见 consle vnc 相关

### 屏幕获取原理

```perl
sub capture_screenshot ($self) {
    return unless $self->{current_screen};

    my $screen = $self->{current_screen}->current_screen();
    $self->enqueue_screenshot($screen) if $screen;
    return;
}
```

依赖 console 的 current_screen 函数实现, 下面介绍 vnc_base 的实现:

TODO:

### TODO: 图片对比

### websocket 客户端注册

所有 websocket 客户端需要通过 isotovideo 的 `/ws` 接口进行注册, 注册后的客户端会保存在 `app->defaults("clients")` 变量中

```perl
sub start_ws ($self) {
    my $id = sprintf "%s", $self->tx;
    $self->app->log->debug('cmdsrv: client connected: ' . $id);
    $self->app->defaults('clients')->{$id} = $self->tx;

    $self->on(
        message => sub ($self, $msg) {
            $self->pass_message_from_ws_client_to_isotovideo($id, $msg);
        });
    $self->on(finish => sub {
            $self->handle_ws_client_disconnects($id);
    });
}
```

### TODO: 测试文件加载

会根据 .pm 和 .pm 处理不同的加载流程

```perl

sub loadtest ($script, %args) {
    no utf8;    # Inline Python fails on utf8, so let's exclude it here
    my $casedir = $bmwqemu::vars{CASEDIR};
    my $script_path = find_script($script);
    my ($name, $category) = parse_test_path($script_path);
    my $test;
    my $fullname = "$category-$name";
    # perl code generating perl code is overcool
    my $code = "package $name;";
    $code .= "use lib '.';" unless path($casedir)->is_abs;
    $code .= "use lib '$casedir/lib';";
    my $basename = dirname($script_path);
    $code .= "use lib '$basename';";
    die "Unsupported file extension for '$script'" unless $script =~ /\.p[my]/;
    my $is_python = 0;
    if ($script =~ m/\.pm$/) {
        $code .= "require '$script_path';";
    }
    elsif ($script =~ m/\.py$/) {
        _debug_python_version();
        # Adding the include path of os-autoinst into python context
        my $inc = File::Basename::dirname(__FILE__);
        my $script_dir = path(File::Basename::dirname($script_path))->to_abs;
        $code .= <<~"EOM";
            use base 'basetest';
            use Inline::Python qw(py_eval py_bind_func py_study_package);
            py_eval(<<'END_OF_PYTHON_CODE');
            import sys
            sys.path.append("$inc")
            sys.path.append("$script_dir")
            import $name
            END_OF_PYTHON_CODE
            # Bind the python functions to the perl $name package
            my %info = py_study_package("$name");
            for my \$func (\@{ \$info{functions} }) {
                py_bind_func("${name}::\$func", "$name", \$func);
            }
            EOM
        $is_python = 1;
    }
    eval $code;
    if (my $err = $@) {
        if ($is_python) {
            eval "use Inline Python => 'sys.stderr.flush()';";
            bmwqemu::fctwarn("Unable to flush Python's stderr, error message from Python might be missing: $@") if $@;
        }
        my $msg = "error on $script: $err";
        bmwqemu::fctwarn($msg);
        bmwqemu::serialize_state(component => 'tests', msg => "unable to load $script, check the log for the cause (e.g. syntax error)");
        die $msg;
    }
    $test = $name->new($category);
    $test->{script} = $script;
    $test->{fullname} = $fullname;
    $test->{serial_failures} = $testapi::distri->{serial_failures} // [];
    $test->{autoinst_failures} = $testapi::distri->{autoinst_failures} // [];

    if (defined $args{run_args}) {
        unless (blessed($args{run_args}) && $args{run_args}->isa('OpenQA::Test::RunArgs')) {
            die 'The run_args must be a sub-class of OpenQA::Test::RunArgs';
        }

        die 'run_args is not supported in Python test modules.' if $is_python;

        $test->{run_args} = $args{run_args};
        delete $args{run_args};
    }

    my $nr = '';
    while (exists $tests{$fullname . $nr}) {
        # to all perl hardcore hackers: fuck off!
        $nr = $nr eq '' ? 1 : $nr + 1;
        $test->{name} = join("#", $name, $nr);
    }
    if ($args{name}) {
        $test->{name} = $args{name};
    }

    $tests{$fullname . $nr} = $test;

    return unless $test->is_applicable;
    push @testorder, $test;

    # Test schedule may change at runtime. Update test_order.json to notify
    # the OpenQA server of the change.
    write_test_order() if $tests_running;
    bmwqemu::diag("scheduling $test->{name} $script");
}
```

### do capture

```perl
sub do_capture ($self, $timeout = undef, $starttime = undef) {
    # Time slot buckets
    my $buckets = {};
    my $wait_time_limit = $bmwqemu::vars{_CHKSEL_RATE_WAIT_TIME} // 30;
    my $hits_limit = $bmwqemu::vars{_CHKSEL_RATE_HITS} // 30_000;

    while (1) {
        # 只有当 cmdpipe 建立之后才进行后续逻辑
        last unless $self->{cmdpipe};

        my $now = gettimeofday;
        # 距离超时还剩的时间
        my $time_to_timeout = $timeout - ($now - $starttime);
        last if $time_to_timeout <= 0;

        # 即使设置了 no_wait 超时时间最少也需要 0.1 秒, 防止消耗过多 cpu (check_screen/assert_screen)
        my $pending_wait_command = $self->{_wait_screen_change} || $self->{_wait_still_screen};
        my @additional_intervals = $pending_wait_command && $pending_wait_command->{no_wait} ? (0.1) : ();

        # TODO: 上次更新?
        my $time_to_update_request = min($self->update_request_interval, @additional_intervals) - ($now - $self->last_update_request);
        if ($time_to_update_request <= 0) {
            $self->request_screen_update();
            $self->last_update_request($now);
            # no need to interrupt loop if VNC does not talk to us first
            $time_to_update_request = $time_to_timeout;
        }

        # 如果屏幕过长时间 (screenshot_interval * 20) 不更新, 认为出错
        if ($self->assert_screen_last_check && $now - $self->last_screenshot > $self->screenshot_interval * 20) {
            $self->stall_detected(1);
            my $diff = $now - $self->last_screenshot;
            bmwqemu::fctwarn "There is some problem with your environment, we detected a stall for $diff seconds";
        }

        # 捕获屏幕, 如果到达超时时间
        my $screenshot_interval = min($self->screenshot_interval, @additional_intervals);
        my $time_to_screenshot = $screenshot_interval - ($now - $self->last_screenshot);
        if ($time_to_screenshot <= 0) {
            # TODO: 具体实现
            $self->capture_screenshot();
            $self->last_screenshot($now);
            $time_to_screenshot = $screenshot_interval;
        }

        # 对比屏幕是否更新: 见 <TODO: 设置锚点>, b把对比结果发送到 rsppipe
        $self->_check_for_screen_change($now) or $self->_check_for_still_screen($now);

        # 更新超时时间
        my $time_to_next = min($time_to_screenshot, $time_to_update_request, $time_to_timeout);

        # 启动 select
        my ($read_set, $write_set) = IO::Select->select($self->{select_read}->select(), $self->{select_write}->select(), undef, $time_to_next);

        # 检查视频编码输出
        my ($video_encoder, $external_video_encoder, $other) = (0, 0, 0);
        for my $fh (@$write_set) {
            if ($fh == $self->{encoder_pipe}) {
                $self->_write_buffered_data_to_file_handle('Encoder', $self->{video_frame_data}, $fh);
                $video_encoder = 1;
            }
            elsif ($fh == $self->{external_video_encoder_cmd_pipe}) {
                $self->_write_buffered_data_to_file_handle('External encoder', $self->{external_video_encoder_image_data}, $fh);
                $external_video_encoder = 1;
            }
            else {
                next if $other;
                $other = 1;
                die "error checking socket for write: $fh\n" unless $self->check_socket($fh, 1) || $other;
            }
            last if $video_encoder == 1 && $external_video_encoder == 1 && $other;
        }

        # 检查 fd read 的频率不能过高
        for my $fh (@$read_set) {
            # 解决 socket 处于半打开状态
            # There are three ways to solve this problem:
            # + Send a message either to the application protocol (null message) or to the application protocol framing (an empty message)
            #   Disadvantages: Requires changes on both ends of the communication. (for example: on SSH connection i realized that after a
            #   while I start getting "bad packet length" errors)
            # + Polling the connections (Note: This is how HTTP servers work when dealing with persistent connections)
            #    Disadvantages: False positives
            # + Change the keepalive packet settings
            #   Disadvantages: TCP/IP stacks are not required to support keepalives.
            if (fileno $fh && fileno $fh != -1) {
                # Very high limits! On a working socket, the maximum hits per 10 seconds will be around 60.
                # The maximum hits per 10 seconds saw on a half open socket was >100k
                if (check_select_rate($buckets, $wait_time_limit, $hits_limit, fileno $fh, time())) {
                    my $console = $self->{current_console}->{testapi_console};
                    my $fd_nr = fileno $fh;
                    my $cnt = $buckets->{BUCKET}{$fd_nr};
                    my $name = $self->{select_read}->get_name($fh);
                    my $msg = "The file descriptor $fd_nr ($name) hit the read attempts threshold of $hits_limit/${wait_time_limit}s by $cnt. ";
                    $msg .= "Active console '$console' is not responding, it could be a half-open socket or you need to increase _CHKSEL_RATE_HITS value. ";
                    $msg .= "Make sure the console is reachable or disable stall detection on expected disconnects with '\$console->disable_vnc_stalls', for example in case of intended machine shutdown.";
                    OpenQA::Exception::ConsoleReadError->throw(error => $msg);
                }
            }

            # check_socket 不只是 check, 还会调用 handle_command 直接执行对应的函数
            die "error checking socket for read: $fh\n" unless $self->check_socket($fh, 0);
            # don't check for further sockets after this one as
            # check_socket can have side effects on the sockets
            # (e.g. console resets), so better take the next socket
            # next time
            last;
        }
    }
}
```
