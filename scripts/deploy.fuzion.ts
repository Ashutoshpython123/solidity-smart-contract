import hre, { ethers } from "hardhat";

const sleep = (ms:any) => new Promise((r) => setTimeout(r, ms));
async function main() {
    const fuzion = await ethers.deployContract("Fuzion");

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
                contract: "contracts/Fuzion.sol:Fuzion",
                address: fuzion.target
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
