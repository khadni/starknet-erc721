%lang starknet

from openzeppelin.token.erc721.library import ERC721
from openzeppelin.token.erc20.IERC20 import IERC20

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_add, uint256_check
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address
from starkware.cairo.common.math import assert_not_zero, split_felt, assert_nn
from openzeppelin.access.ownable.library import Ownable
from openzeppelin.token.erc721.enumerable.library import ERC721Enumerable

#
# Structs
#
struct Animal:
    member sex : felt
    member legs : felt
    member wings : felt
end

#
# Utils
#

func felt_to_uint256{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    felt_value : felt
) -> (uint256_value : Uint256):
    let (high, low) = split_felt(felt_value)
    let uint256_value : Uint256 = Uint256(low, high)
    return (uint256_value)
end

#
# Storage vars
#

@storage_var
func last_token_id() -> (token_id : Uint256):
end

@storage_var
func animals(token_id : Uint256) -> (animal : Animal):
end

@storage_var
func _breeders(address : felt) -> (is_breeder : felt):
end

# @storage_var
# func dead_animals(token_id : Uint256) -> (is_dead : felt):
# end

@storage_var
func _dummy_token_address() -> (dummy_token_address : felt):
end


#
# Constructor
#

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    name : felt, symbol : felt, owner : felt, dummy_token_address : felt
):
    ERC721.initializer(name, symbol)
    Ownable.initializer(owner)
    # let to = to_
    token_id_initializer()
    # let token_id : Uint256 = Uint256(1, 0)
    # ERC721._mint(to, token_id)
    _dummy_token_address.write(dummy_token_address)
    return ()
end
func token_id_initializer{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}():
    let zero_as_uint256 : Uint256 = Uint256(0, 0)
    last_token_id.write(zero_as_uint256)
    return ()
end

#
# Getters
#

@view
func name{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (name : felt):
    let (name) = ERC721.name()
    return (name)
end

@view
func symbol{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (symbol : felt):
    let (symbol) = ERC721.symbol()
    return (symbol)
end

@view
func balanceOf{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(owner : felt) -> (
    balance : Uint256
):
    let (balance : Uint256) = ERC721.balance_of(owner)
    return (balance)
end

@view
func ownerOf{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256
) -> (owner : felt):
    let (owner : felt) = ERC721.owner_of(token_id)
    return (owner)
end

@view
func getApproved{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256
) -> (approved : felt):
    let (approved : felt) = ERC721.get_approved(token_id)
    return (approved)
end

@view
func isApprovedForAll{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    owner : felt, operator : felt
) -> (is_approved : felt):
    let (is_approved : felt) = ERC721.is_approved_for_all(owner, operator)
    return (is_approved)
end

@view
func get_animal_characteristics{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256
) -> (sex : felt, legs : felt, wings : felt):
    with_attr error_message("ERC721: token_id is not a valid Uint256"):
        uint256_check(token_id)
    end
    let animal = animals.read(token_id)
    let animal_ptr = cast(&animal, Animal*)
    return (sex=animal_ptr.sex, legs=animal_ptr.legs, wings=animal_ptr.wings)
end

@view 
func is_breeder{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(address : felt) -> (res : felt):
    with_attr error_message("ERC721: the zero address can't be a breeder"):
        assert_not_zero(address)
    end
    let (res : felt) = _breeders.read(address)
    return (res)
end

# @view
# func get_is_dead{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(token_id : felt) -> (is_dead : felt):
#     let(is_dead : felt) = dead_animals.read(token_id)
#     return (is_dead)
# end

@view
func token_of_owner_by_index{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    account : felt, index : felt
) -> (token_id : Uint256):
    alloc_locals
    with_attr error_message("ERC721: the zero address is not supported as a token holder"):
        assert_not_zero(account)
    end
    with_attr error_message("ERC721: index must be a positive integer"):
    assert_nn(index)
    end
    let (index_uint256) = felt_to_uint256(index)
    let (token_id) = ERC721Enumerable.token_of_owner_by_index(owner=account, index=index_uint256)
    return (token_id)
end

@view
func registration_price{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    price : Uint256
):
    let two_as_uint256 = Uint256(2, 0)
    return (price=two_as_uint256)
end

#
# Externals
#

@external
func approve{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    to : felt, token_id : Uint256
):
    ERC721.approve(to, token_id)
    return ()
end

@external
func setApprovalForAll{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    operator : felt, approved : felt
):
    ERC721.set_approval_for_all(operator, approved)
    return ()
end

@external
func transferFrom{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    from_ : felt, to : felt, token_id : Uint256
):
    ERC721Enumerable.transfer_from(from_, to, token_id)
    return ()
end

@external
func safeTransferFrom{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    from_ : felt, to : felt, token_id : Uint256, data_len : felt, data : felt*
):
    ERC721Enumerable.safe_transfer_from(from_, to, token_id, data_len, data)
    return ()
end

@external
func declare_animal{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    sex : felt, legs : felt, wings : felt
) -> (token_id : Uint256):
    alloc_locals
    assert_only_breeder()
 
    # Increment token_id by 1
    let current_token_id : Uint256 = last_token_id.read()
    let one_as_uint256 = Uint256(1, 0)
    let (local new_token_id, _) = uint256_add(current_token_id, one_as_uint256)
 
    let (sender_address) = get_caller_address()
 
    # Mint NFT and update token_id
    ERC721Enumerable._mint(sender_address, new_token_id)
    animals.write(new_token_id, Animal(sex=sex, legs=legs, wings=wings))

    # Update and return new token id
    last_token_id.write(new_token_id)
    return (token_id=new_token_id)
end

func assert_only_breeder{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    let (sender_address) = get_caller_address()
    let (is_true) = _breeders.read(sender_address)
    with_attr error_message("Caller is not a registered breeder"):
        assert is_true = 1
    end
    return ()
end


@external
func register_me_as_breeder{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (address : felt):
    let (sender_address) = get_caller_address()
    let (erc721_address) = get_contract_address()
    let (price) = registration_price()
    let (dummy_token_address) = _dummy_token_address.read()
 
    let (success) = IERC20.transferFrom(
        contract_address=dummy_token_address,
        sender=sender_address,
        recipient=erc721_address,
        amount=price,
    )
    with_attr error_message("ERC721: unable to charge dummy tokens"):
        assert success = 1
    end
    _breeders.write(address=sender_address, value=1)
    return (address=1)
end

@external
func unregister_me_as_breeder{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() ->
    (address : felt):
    let (sender_address) = get_caller_address()
    _breeders.write(address=sender_address, value=0)
    return (address=0)
end

@external
func declare_dead_animal{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256):
    #only contract owner can add a breeder
    ERC721.assert_only_token_owner(token_id)
    ERC721Enumerable._burn(token_id)
    return()
end