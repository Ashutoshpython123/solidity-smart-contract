import hre, { ethers } from "hardhat";

const sleep = (ms:any) => new Promise((r) => setTimeout(r, ms));
async function main() {
    const owner = "0x6E6114cA36f604c59b301D0268AD0e1541775B38"
    const name = "Token Staking"
    const roi = 900;
    const lockduration = 1;
    const stake = await ethers.deployContract("TokenStaking", [owner, name, roi, lockduration]);


    await stake.waitForDeployment();

    console.log(
        `contract deployed to ${stake.target}`
    );

        //verification of the smart contract
        const waitTime = 60;
        console.log(`Trying to verify after ${waitTime}s...`);
        await sleep(waitTime * 1000);
        try {
            await hre.run("verify:verify", {
                contract: "contracts/TokenStaking.sol:TokenStaking",
                address: stake.target,
                constructorArguments : [owner, name, roi, lockduration]
            });
        } catch (e:any) {
            if (e.message.includes("Reason: Already Verified")) {
                return
            }
            console.log(`Failed to verify. Retrying...`, e);
        }
        console.log("Done!");
}
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
