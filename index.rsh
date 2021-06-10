'reach 0.1';

import { bountyFunction } from 'bountyFunction.rsh';

const UserEntryType = Object({
    accountAddress: Address,
    returnValue: UInt,
    inputValue: UInt,
});

const LEADERBOARD_SIZE = 3;

const CommonInterface =
{
    informBounty: Fun([UInt, UInt], Null),
    ping: Fun([Array(UserEntryType, LEADERBOARD_SIZE)], Null)
}

const FunderInterface =
{
    ...CommonInterface,
    getBounty: Fun([], Object({
        deadline: UInt,
        amt: UInt,
    })),
}

const LeaderboardViewInterface =
{
    leaderboard: Array(UserEntryType, LEADERBOARD_SIZE)
}

const ContestantInterface =
{
    ...CommonInterface,
    submitValue: Fun([], Maybe(UInt)),
    informWinner: Fun([Address], Null),
    informSucc: Fun([Bool], Null)
}

export const main =
    Reach.App(
        {},
        [Participant('Funder', FunderInterface), ParticipantClass('Contestant', ContestantInterface), View('Leaderboard', LeaderboardViewInterface)],
        (Funder, Contestant, LeaderboardView) => {

            Funder.only(() => {
                const { amt, deadline } = declassify(interact.getBounty());
            });

            //TODO: the deadline expression of a timeout clause can be any equation over consensus state. https://docs.reach.sh/guide-timeout.html 
            Funder.publish(amt, deadline)
                .pay(amt);

            each([Contestant], () => {
                interact.informBounty(amt, deadline);
            });

            const initLeaderboard = Array.replicate(LEADERBOARD_SIZE, {
                accountAddress: Funder,
                returnValue: 0,
                inputValue: 0,
            });
            LeaderboardView.leaderboard.set(initLeaderboard);

            const [keepGoing, currentWinner, leaderboard] =
                parallelReduce([true, { accountAddress: Funder, returnValue: 0, inputValue: 0}, initLeaderboard])
                    .invariant(balance() == amt)
                    .while(keepGoing)
                    .case(
                        Contestant,
                        (() => {
                            const value = declassify(interact.submitValue());
                            return {
                                when: isSome(value),
                                msg: value
                            }
                        }),
                        ((msg) => {
                            const currentContestant = this;
                            Contestant.only(() => interact.informSucc(true))
                            const inputValue = fromSome(msg, 0);
                            const evaluatedValue = bountyFunction(inputValue);
                            const newEntry = {
                                accountAddress: currentContestant,
                                inputValue: inputValue,
                                returnValue: evaluatedValue,
                            };

                            const [isChanged, _, newLeaderboard] = leaderboard.reduce([false, 0, leaderboard], ([found, idx, newArr], elem) => {
                                if (found) {
                                    Contestant.only(() => interact.ping(leaderboard))
                                    if (idx + 1 < newArr.length) {
                                        return [found, idx + 1, newArr.set(idx + 1, elem)];
                                    } else {
                                        return [found, idx, newArr];
                                    }
                                } else {
                                    if (elem.returnValue < newEntry.returnValue) {
                                        if (idx + 1 < newArr.length) {
                                            return [true, idx + 1, newArr.set(idx, newEntry)];
                                        } else {
                                            return [true, idx, newArr];
                                        }
                                    } else {
                                        return [false, idx + 1, newArr];
                                    }
                                }
                            })
                            if (isChanged) {
                                LeaderboardView.leaderboard.set(newLeaderboard);
                                commit();
                                Contestant.publish();
                            }
                            const newWinner = evaluatedValue > currentWinner.returnValue ? newEntry : currentWinner;
                            return [true, newWinner, newLeaderboard];
                        })
                    )
                    .timeout(deadline, () => {
                        Anybody.publish();
                        return [false, currentWinner, leaderboard];
                    });

            transfer(balance()).to(currentWinner.accountAddress);
            commit();

            exit();
        }
    );
