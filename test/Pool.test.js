const truffleAssert = require('truffle-assertions');

const Pool = artifacts.require("Pool");


contract('CrowdTest', ([deployer, initiator, a, b, c]) => {
    before(async () => {
        pool = await Pool.new("0xF52B67C2241B0F7ab3b7643a0c78DAd0cB39a6A4");
    })

    describe("Testing Pool", async () => {
        before(async () => {
            deposit_a = web3.utils.toWei("0.03", "ether")
            deposit_b = web3.utils.toWei("0.03", "ether")
            deposit_c = web3.utils.toWei("0.04", "ether")
        })
        it('Creates new party', async () => {
            tx = await pool.new_party(mock_nft.address, 1, party_name, ticker);
            truffleAssert.eventEmitted(tx,
                'NewParty',
                (ev) => {return (ev.pool_id).toNumber() === 1}
            )
        })
        it('Add assets to pool', async () => {
            // user a
            await pool.set_deposit(1, {from: a, value: deposit_a});
            call = await pool.check_participant_in_pool(1, a);
            assert.equal(call, true);
            call = await pool.get_absolute(1, a);
            assert.equal(call, deposit_a)
            // user b
            await pool.set_deposit(1, {from: b, value: deposit_b});
            call = await pool.check_participant_in_pool(1, b);
            assert.equal(call, true);
            call = await pool.get_absolute(1, b);
            assert.equal(call, deposit_b);
            // user c
            await pool.set_deposit(1, {from: c, value: deposit_c});
            call = await pool.check_participant_in_pool(1, c);
            assert.equal(call, true);
            call = await pool.get_absolute(1, c);
            assert.equal(call, deposit_c);
        })
        it('Check pool total', async () => {
            call = await pool.get_total(1);
            assert.equal(call, web3.utils.toWei("0.1", "ether"));  // ToDo remove hardcode
        })
    })})
