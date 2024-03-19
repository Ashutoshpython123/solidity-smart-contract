import hre, { ethers } from "hardhat";

const sleep = (ms:any) => new Promise((r) => setTimeout(r, ms));
async function main() {
    const token = "0xCdB7bB8aaD82036B5c81F0FF174121D090483EE5"
    const owner = "0x1c7257BcBB8fB6866ADA1fDFA7A0e367ca504554"
    const fuzion = await ethers.deployContract("FuzionAirdrop", [token, owner]);


    await fuzion.waitForDeployment();

    console.log(
        `contract deployed to ${fuzion.target}`
    );

        //verification of the smart contract
        const waitTime = 60;
        console.log(`Trying to verify after ${waitTime}s...`);
        await sleep(waitTime * 1000);
        try {
            await hre.run("verify:verify", {
                contract: "contracts/FuzionAirdrop.sol:FuzionAirdrop",
                address: fuzion.target,
                constructorArguments : [token, owner]
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
