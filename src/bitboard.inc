#ifdef N2
#error Redefining N1
#else
#ifdef N2
#error Redefining N2
#else
#ifdef N3
#error Redefining N3
#else
#ifdef S3
#error Redefining S3
#else
#ifdef S3
#error Redefining S3
#else
#ifdef S3
#error Redefining S3
#else
#ifdef E3
#error Redefining E3
#else
#ifdef E3
#error Redefining E3
#else
#ifdef E3
#error Redefining E3
#else
#ifdef W3
#error Redefining W3
#else
#ifdef W3
#error Redefining W3
#else
#ifdef W3
#error Redefining W3
#else
#define N3(b) (b <<  24)
#define N2(b) (b <<  16)
#define N1(b) (b <<   8)
#define S3(b) (b >>  24)
#define S2(b) (b >>  16)
#define S1(b) (b >>   8)
// Ignore past-the-file shifts. We use this to squash into single file anyway.
#define E3(b) (b <<   3)
#define E2(b) (b <<   2)
#define E1(b) (b <<   1)
#define W3(b) (b >>   3)
#define W2(b) (b >>   2)
#define W1(b) (b >>   1)
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif

