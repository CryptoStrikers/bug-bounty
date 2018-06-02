# The CryptoStrikers Bounty Program

## Our version of the [bug bounty](https://github.com/dapperlabs/cryptokitties-bounty) ran by the awesome folks at [CryptoKitties](https://www.cryptokitties.co/) late last year!

CryptoStrikers recognizes the importance of security researchers in keeping our community safe and fun. With the launch of CryptoStrikers around the corner, we would love the community to help provide disclosure of security vulnerabilities via our bounty program described below.

**Pretty much everything you need to know about the project is [here](./CryptoStrikers%20Basics.md)**

### The Scope for this Bounty Program:

This bounty program will run on the Rinkeby network from <b>11:00am ET on June 1st until 11:59pm ET on June 5th, 2018</b>. All code important to this bounty program is publicly available within this repo.

Help us identify bugs, vulnerabilities, and exploits in the smart contract such as:
- Breaking the core game mechanics (eg. purchasing card packs or trading no longer work).
- Incorrect usage of the game.
- Stealing a card from someone else.
- Draining the contract of money.
- Acting as one of the admin accounts.
- Minting cards at will, or minting more of a card than there should ever be.
- Gaming our referral or whitelist programs.
- Any other sort of malfunction.

### Rules & Rewards:

- Issues that have already been submitted by another user or are already known to the CryptoStrikers team are not eligible for bounty rewards.
- Bugs and vulnerabilities should only be found using accounts you own and create. Please respect third party applications and understand that an exploit that is not specific to a CryptoStrikers smart contract is not part of the bounty program. Attacks on the network that result in bad behaviour are not allowed.
- Don’t perform any attack that could harm the reliability/integrity of our website, services or data (e.g., DDoS/spam attacks are **not** allowed!).
- The CryptoStrikers website is not part of the bounty program, only the smart contract code included in this repo.
- The CryptoStrikers bounty program considers a number of variables in determining rewards. Determinations of eligibility, score and all terms related to a reward are at the sole and final discretion of CryptoStrikers team.
- Reports will only be accepted via GitHub issues submitted to this repo.
- In general, please investigate and report bugs in a way that makes a reasonable, good faith effort not to be disruptive or harmful to us or others.
- We abide by our golden rule and want you to as well: DON’T BE A JERK.
- When in doubt, contact us at bounty@cryptostrikers.com


The value of rewards paid out will vary depending on Severity which is calculated based on Impact and Likelihood as followed by  [OWASP](https://www.owasp.org/index.php/OWASP_Risk_Rating_Methodology):

![Alt text](https://github.com/CryptoStrikers/bug-bounty/blob/master/owasp_w600.png)

<b>Note: Rewards are at the sole discretion of the CryptoStrikers Team. 1 point currently corresponds to 1 USD (paid in ETH) The top 10 people on our leaderboard of accepted bugs with at least 250 points will receive a limited edition CryptoStrikers card available only to successful participants in this bounty program. The hard cap for total points claimed across the bug bounty is 5000.</b>

- Critical: up to 1000 points
- High: up to 500 points
- Medium: up to 250 points
- Low: up to 125 points
- Note: up to 50 points

<b> Examples of Impact: </b>
- High: Steal a card from someone, drain ETH from the contract, able to mint an infinite amount of cards, render the game unplayable for others.
- Medium: Game the referral or whitelist program, remove cards from circulation.
- Low: Cancel someone else's trades, remove other people from the whitelist.

<b>Suggestions for Getting the Highest Score:</b>
- Description: Be clear in describing the vulnerability or bug. Ex. share code scripts, screenshots or detailed descriptions.
- Fix it: if you can suggest how we fix this issue in an appropriate manner, higher points will be rewarded.

<b>CryptoStrikers appreciates you taking the time to participate in our program, which is why we’ve created rules for us too:</b>
- We will respond as quickly as we can to your submission (within 2 days).
- Let you know if your submission will qualify for a bounty (or not) within 5 business days.
- We will keep you updated as we work to fix the bug you submitted.
- CryptoStrikers' core development team, employees and all other people paid by the CryptoStrikers project, are not eligible for rewards.

<b>How to Create a Good Vulnerability Submission:</b>
- <b>Description:</b> A brief description of the vulnerability
- <b>Scenario:</b> A description of the requirements for the vulnerability to happen
- <b>Impact:</b> The result of the vulnerability and what or who can be affected
- <b>Reproduction:</b> Provide the exact steps on how to reproduce this vulnerability on a new contract, and if possible, point to specific tx hashes or accounts used.
- <b>Note:</b> If we can't reproduce with given instructions then a (Truffle) test case will be required.
- <b>Fix:</b> If applies, what would would you do to fix this

<b>FAQ:</b>
- How are the bounties paid out?
  - Rewards are paid out in ETH after the submission has been validated, usually a few days later. Please provide your ETH address.
- I reported an issue but have not received a response!
  - We aim to respond to submissions as fast as possible. Feel free to email us at bounty@cryptostrikers.com if you have not received a response.
- Can I use this code elsewhere?
  - No. Please do not copy this code for other purposes than reviewing it.
- I have more questions!
  - Create a new issue with the title starting as “QUESTION”
- Will the code change during the bounty?
  - Yes, as issues are reported we will update the code as soon as possible. Please make sure your bugs are reported against the latest versions of the published code.
- Having trouble with anything?
  - Join the [#bug-bounty channel on the CryptoStrikers Discord](https://discord.gg/nQUy3Pc) to get some assistance!


<b>Important Legal Information:</b>

**THE BUG BOUNTY PROGRAM IS AN EXPERIMENTAL REWARDS PROGRAM FOR OUR COMMUNITY TO ENCOURAGE AND REWARD THOSE WHO ARE HELPING US TO IMPROVE CRYPTOSTRIKERS. YOU SHOULD KNOW THAT WE CAN CLOSE THE PROGRAM AT ANY TIME, AND REWARDS ARE AT THE SOLE DISCRETION OF THE CRYPTOSTRIKERS TEAM. ALL REWARDS ARE SUBJECT TO APPLICABLE LAW AND THUS APPLICABLE TAXES. DON'T TARGET OUR PHYSICAL SECURITY MEASURES, OR ATTEMPT TO USE SOCIAL ENGINEERING, SPAM, DISTRIBUTED DENIAL OF SERVICE (DDOS) ATTACKS, ETC. LASTLY, YOUR TESTING MUST NOT VIOLATE ANY LAW OR COMPROMISE ANY DATA THAT IS NOT YOURS.**

Copyright (c) 2018 CRYPTOSTRIKERS LLC

All rights reserved. The contents of this repository are provided for review and educational purposes ONLY. You MAY NOT use, copy, distribute, or modify this software without express written permission from CRYPTOSTRIKERS LLC.

