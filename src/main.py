from telegram.client import Telegram

key_file="./assets/keys"
help_file="./assets/help"
bot_commands = "ERROR: help file missing"

# Our init function
def init():
    api_id=None
    api_hash=None
    bot_token=None
    database_encryption_key=None

    try:
        global bot_commands
        bot_commands = open(help_file, "r").read()
    except:
        print("Help file missing")

    f = open(key_file, "r")
    for line in f:
        split = line[0:-1].split("=")
        key = split[0]
        val = split[1]
        if key == "api_id":
            api_id = val
        elif key == "api_hash":
            api_hash = val
        elif key == "bot_token":
            bot_token = val
        elif key == "database_encryption_key":
            database_encryption_key = val

    if api_id == None or api_hash == None or bot_token == None or database_encryption_key == None:
        print("There is an error in your config, located in %s" % key_file)
        exit(1)

    return Telegram(
            api_id=api_id,
            api_hash=api_hash,
            bot_token=bot_token,
            database_encryption_key=database_encryption_key
            )

def server_status():
    return "TODO"

def new_message_handler(update):
        content = update['message']['content'].get('text', {})
        text = content.get('text', '').lower()
        chat_id = update['message']['chat_id']
        ret = None

        if text == "status":
            ret = server_status()
        elif text == "help":
            ret = bot_commands

        if ret != None:
            tg.send_message(chat_id=chat_id, text=str(ret))

tg = init()
tg.login()
tg.add_message_handler(new_message_handler)
tg.idle()  # blocking waiting for CTRL+C
