import sys
import os

def usage():
    print("Usage: !<cmd> [params]")

def help(user, cmd, params):
    print("Commands:", ", ".join([k for k in cmd_list.keys()]))

def github(user, cmd, params):
        print(str("@%s: https://github.com/gitabaz" % user))

def olab0t(user, cmd, params):
        print(str("@%s: https://github.com/gitabaz/olab0tv2" % user))

def set(user, cmd, params):
    if user == "olabaz":
        param_list = params.split()
        key = param_list[0]
        value = " ".join(param_list[1:])
        fn = str("./commands/artifacts/%s" % key)
        with open(fn, "w") as f:
            f.write(value)
            print(key, "set to:", value, "SeemsGood")

def motd(user, cmd, params):
    fn = "./commands/artifacts/motd"
    if os.path.exists(fn):
        with open(fn, "r") as f:
            contents = f.read()
            print(str("@%s: %s" % (user, contents)))
    else:
        print(cmd, "not set")


cmd_list = {
    "help": help,
    "github": github,
    "olab0t": olab0t,
    "set": set,
    "motd": motd,
}

def handle_command(user, cmd, params):
    cmd_fn = cmd_list.get(cmd, None)
    if cmd_fn:
        cmd_fn(user, cmd, params)

def main():
    if len(sys.argv) == 1:
        usage()
    else:
        user = sys.argv[1]
        cmd = sys.argv[2][1:]
        params = None
        try:
            params = sys.argv[3].strip()
        except:
            pass

        handle_command(user, cmd, params)

if __name__ == "__main__":
    main()
