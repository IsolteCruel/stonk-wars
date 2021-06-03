'reach 0.1';

const UserEntryType = Object({
    accountAddress: Address,
    returnValue: UInt,
    inputValue: UInt,
    timestamp: UInt
});

const LEADERBOARD_SIZE = 3;

const CommonInterface =
{
    informBounty: Fun([UInt, UInt], Null),
    //TODO: check how to send leaderboard, perhaps maintain top X in an array
    //TODO: looks like map doesn't work kek
    informLeaderboard: Fun([Array(UserEntryType, LEADERBOARD_SIZE)], Null)
}

const FunderInterface =
{
    ...CommonInterface,
    getBounty: Fun([], Object({
        deadline: UInt,
        amt: UInt,
    })),
    // bounty: Fun([UInt], UInt)
}

const ContestantInterface =
{
    ...CommonInterface,
    submitValue: Fun([], Maybe(UInt)),
    // shouldSubmitValue: Fun([], Bool),
    informWinner: Fun([Address], Null)
}

export const main =
    Reach.App(
        {},
        [Participant('Funder', FunderInterface), ParticipantClass('Contestant', ContestantInterface)],
        (Funder, Contestant) => {

            const bountyFunction = (a) => (a % 69);

            Funder.only(() => {
                const { amt, deadline } = declassify(interact.getBounty());
            });
            //TODO: the deadline expression of a timeout clause can be any equation over consensus state. https://docs.reach.sh/guide-timeout.html 
            Funder.publish(amt, deadline)
                .pay(amt);
            // commit();

            each([Contestant], () => {
                interact.informBounty(amt, deadline);
            });

            // const initLeaderboard = new Map(UserEntryType);
            const initLeaderboard = Array.replicate(LEADERBOARD_SIZE, {
                accountAddress: Funder,
                returnValue: 0,
                inputValue: 0,
                timestamp: 0
            });
            // commit();

            const [keepGoing, currentWinner, leaderboard] =
                //TODO: timestamp is currently ignored kek
                parallelReduce([true, { accountAddress: Funder, returnValue: 0, inputValue: 0, timestamp: 0 }, initLeaderboard])
                    .invariant(balance() == amt)
                    .while(keepGoing)
                    .case(
                        Contestant,
                        (() => {
                            const value = declassify(interact.submitValue());
                            return {
                                // value = declassify(interact.submitValue(ticketPrice));
                                // return {

                                when: isSome(value),
                                msg: value
                                // }
                                // if (isSome(value)) {
                                //     return {
                                //         when: true,
                                //         msg: value
                                //     }
                                // }
                                // else {
                                //     return {
                                //         when: false
                                //     }
                                // }
                            }
                        }),
                        // ((_) => 0),
                        ((msg) => {
                            const currentContestant = this;
                            // const value 
                            const inputValue = fromSome(msg, 0);
                            const evaluatedValue = bountyFunction(inputValue);
                            // previousEntry = leaderboard[currentContestant];
                            // if (isSome(previousEntry)) {
                            //     if (evaluatedValue > previousEntry.returnValue) {
                            const newEntry = {
                                accountAddress: currentContestant,
                                inputValue: inputValue,
                                returnValue: evaluatedValue,
                                timestamp: 0
                            };
                            // const curr = 0;
                            // leaderboard.forEach((item, index) => {
                            //     if(item.returnValue < newEntry.returnValue) {
                            //         find = index;
                            //     }
                            // })
                            // var [index, foundIndex, found, loopLeaderboard] = [0, 0, false, leaderboard];
                            // const found = false;
                            // var foundIndex = -1;
                            // var index = 0;
                            // const loopLeaderboard = leaderboard.map((item) => {
                            //     if (foundIndex != -1) {
                            //         // leaderboard[index] = leaderboard[index - 1];
                            //         return leaderboard[index - 1];
                            //         // leaderboard = loopLeaderboard;
                            //     }
                            //     else if(leaderboard[index].returnValue < newEntry.returnValue) {
                            //         [foundIndex, index] = [index, index];
                            //         return newEntry;
                            //     }
                            //     return leaderboard[index];
                            // })
                            // invariant(index <= loopLeaderboard.length && foundIndex < loopLeaderboard.length && balance() == amt);
                            // while (index < loopLeaderboard.length) {
                            //     // const tempLeaderboard;
                            //     // const tempFoundIndex;
                            //     commit();
                            //     if (found) {
                            //         // leaderboard[index] = leaderboard[index - 1];
                            //         // tempLeaderboard = leaderboard.set(index, leaderboard[index - 1]);
                            //         // tempFoundIndex = foundIndex;
                            //         [index, loopLeaderboard] = [index + 1, leaderboard.set(index, leaderboard[index - 1])];
                            //         continue;
                            //         // leaderboard = loopLeaderboard;
                            //     }
                            //     if (leaderboard[index].returnValue < newEntry.returnValue) {
                            //         // found = true;
                            //         // tempLeaderboard = leaderboard;
                            //         // tempFoundIndex = index;
                            //         [foundIndex, index, found] = [index, index + 1, true];
                            //         continue;

                            //     }
                            //     continue;
                            // }
                            // const newLeaderboard = found && foundIndex < loopLeaderboard.length ? loopLeaderboard.set(foundIndex, newEntry) : loopLeaderboard;

                            // found ?
                            //     [found, (idx + 1 < newArr.length ? idx + 1 : idx), (idx + 1 < newArr.length ? newArr.set(idx + 1, elem) : newArr)]
                            //     : (elem.returnValue < newEntry.returnValue ?
                            //         [true, (idx + 1 < newArr.length ? idx + 1 : idx), newArr.set(idx, newEntry)]
                            //         : [false, (idx + 1 < newArr.length ? idx + 1 : idx), newArr])
                            const newLeaderboard = leaderboard;
                            // const [_, _, newLeaderboard] = leaderboard.reduce([false, 0, leaderboard], ([found, idx, newArr], elem) => {
                            //     if (found) {
                            //         if (idx + 1 < newArr.length) {
                            //             return [found, idx + 1, newArr.set(idx + 1, elem)];
                            //         } else {
                            //             return [found, idx, newArr];
                            //         }
                            //     } else {
                            //         if (elem.returnValue < newEntry.returnValue) {
                            //             if (idx + 1 < newArr.length) {
                            //                 return [true, idx + 1, newArr.set(idx, newEntry)];
                            //             } else {
                            //                 return [false, idx, newArr];
                            //             }
                            //         } else {
                            //             return [false, idx + 1, newArr];
                            //         }
                            //     }
                            // })
                            // if (foundIndex != -1) {
                            //     leaderboard[foundIndex] = newEntry;
                            // }
                            // leaderboard[currentContestant] = newEntry;
                            const newWinner = evaluatedValue > currentWinner.returnValue ? newEntry : currentWinner;

                            //     }
                            // }
                            return [true, newWinner, newLeaderboard];
                        })
                    )
                    .timeout(deadline, () => {
                        Anybody.publish();
                        return [false, currentWinner, leaderboard];
                    });


            // commit();

            Funder.only(() => {
                interact.informLeaderboard(leaderboard);
            });

            transfer(balance()).to(currentWinner.accountAddress);
            commit();

            exit();
        }
    );