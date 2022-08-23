%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_add, uint256_check
from starkware.starknet.common.syscalls import get_caller_address
from openzeppelin.access.ownable.library import Ownable
from openzeppelin.token.erc721.library import ERC721


#
# Structs
#
struct Animal:
    member sex : felt
    member legs : felt
    member wings : felt
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


#
# Constructor
#

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    name : felt, symbol : felt, owner : felt
):
    ERC721.initializer(name, symbol)
    Ownable.initializer(owner)
    # let to = to_
    token_id_initializer()
    # let token_id : Uint256 = Uint256(1, 0)
    # ERC721._mint(to, token_id)
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
    _from : felt, to : felt, token_id : Uint256
):
    ERC721.transfer_from(_from, to, token_id)
    return ()
end

@external
func safeTransferFrom{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    _from : felt, to : felt, token_id : Uint256, data_len : felt, data : felt*
):
    ERC721.safe_transfer_from(_from, to, token_id, data_len, data)
    return ()
end

@external
func declare_animal{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    sex : felt, legs : felt, wings : felt
) -> (token_id : Uint256):
    alloc_locals
    Ownable.assert_only_owner()
 
    # Increment token_id by 1
    let current_token_id : Uint256 = last_token_id.read()
    let one_as_uint256 = Uint256(1, 0)
    let (local new_token_id, _) = uint256_add(current_token_id, one_as_uint256)
 
    let (sender_address) = get_caller_address()
 
    # Mint NFT and update token_id
    ERC721._mint(sender_address, new_token_id)
    animals.write(new_token_id, Animal(sex=sex, legs=legs, wings=wings))

    # Update and return new token id
    last_token_id.write(new_token_id)
    return (token_id=new_token_id)
end