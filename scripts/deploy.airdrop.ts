import hre, { ethers } from "hardhat";

const sleep = (ms:any) => new Promise((r) => setTimeout(r, ms));
async function main() {
    const token = "0x7f16e5f955278C896d314C034890B427E6977533"
    const owner = "0x6E6114cA36f604c59b301D0268AD0e1541775B38"
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
