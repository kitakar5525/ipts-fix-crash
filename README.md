# ipts-fix-crash

Trying to fix an issue "IPTS stops working" after some amount of use on some SB1/SP4.

See [Touch and pen issue persists · Issue #374 · jakeday/linux-surface](https://github.com/jakeday/linux-surface/issues/374)

#### 2020-06-24

Hopefully, this issue has been fixed by commit [linux-surface/kernel@8b45a31eb597](https://github.com/linux-surface/kernel/commit/8b45a31eb5977d79ec2099e80c0c3bddf7b38aee) ("ipts: Simplify feedback implementation") and the quirk `no_feedback` has been finally removed.
