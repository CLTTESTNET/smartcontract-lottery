def start_lottery():
    account = get_account()
    # get the latest lottery:
    lottery = Lottery[-1]
    starting_tx = lottery.startLottery({"from": account})
    starting_tx.wait(1)
    print(lottery)
    print("Lottery started!!!")