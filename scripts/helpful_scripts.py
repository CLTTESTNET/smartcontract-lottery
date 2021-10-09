from brownie import (
    accounts,
    network,
    config,
    MockV3Aggregator,
    VRFCoordinatorMock,
    LinkToken,
    Contract,
    interface,
)

# __init__ - enabling python to recognize a script as a package

FORKED_LOCAL_ENVIRONMENT = ["mainnet-fork", "mainnet-fork-dev"]
LOCAL_BLOCKCHAIN_ENVIRONMENT = ["development", "ganache-local"]


def get_account(index=None, id=None):
    if index:
        return accounts[index]
    if id:
        return accounts.load(id)

    if (
        network.show_active() == "FORKED_LOCAL_ENVIRONMENT"
        or network.show_active() == "LOCAL_BLOCKCHAIN_ENVIRONMENT"
    ):
        return accounts[0]

    # - Default account
    return accounts.add(config["wallets"]["from_key"])


contract_to_mock = {
    "eth_usd_price_feed": MockV3Aggregator,
    "vrf_coordinator": VRFCoordinatorMock,
    "link_token": LinkToken,
}


def get_contract(contract_name):

    """This function will grab the contract addresses from brownie config,
    otherwise it will deploy a mock version of the contract and
    return that mock contract

    Args:
                contract_name (string)
            Returns:
                brownie.network.contract.ProjectContract: The most recently deployed
                version of this contract.

    """
    contract_type = contract_to_mock[contract_name]
    if network.show_active() in LOCAL_BLOCKCHAIN_ENVIRONMENT:
        if len(contract_type) <= 0:
            deploy_mocks()

        contract = contract_type[-1]  # same as MockV3Aggregator[-1]
    else:
        contract_address = config(["networks"][network.show_active()][contract_name])
        # we need address
        # we need abi
        contract = Contract.from_abi(
            contract_type._name, contract_address, contract_type.abi
        )
    return contract


DECIMALS = 8
STARTING_VALUE = 200000000000


def deploy_mocks(decimals=DECIMALS, initial_value=STARTING_VALUE):
    account = get_account()
    # if len(MockV3Aggregator) <= 0:
    MockV3Aggregator.deploy(decimals, initial_value, {"from": get_account()})
    link_token = LinkToken.deploy({"from": account})
    VRFCoordinatorMock.deploy(link_token.address, {"from": account})
    print("Mocks Deployed!!!")


def fund_with_link(
    contract_address, account=None, link_token=None, amount=100000000000000000
):  # 0.1 Link
    account = account if account else get_account()
    link_token = link_token if link_token else get_contract("link_token")
    tx = link_token.transfer(contract_address, amount, {"from": account})
    # link_token_contract = interface.LinkTokenInterface(link_token.address)
    # tx = link_token_contract.transfer(contract_address, amount, {"from": account})
    tx.wait(1)
    print("fund contract")
    return tx


def main():
    get_account()
