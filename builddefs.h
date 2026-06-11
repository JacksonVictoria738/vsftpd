#ifndef VSF_BUILDDEFS_H
#define VSF_BUILDDEFS_H

/*
 * Embedded / minimal build configuration.
 * All external library dependencies are disabled.
 * - No PAM: embedded systems rarely have libpam
 * - No SSL: keep it simple, no crypto dependencies
 * - No TCP wrappers: not needed for simple use cases
 *
 * To re-enable a feature, change the #undef to #define.
 */
#undef VSF_BUILD_TCPWRAPPERS
#undef VSF_BUILD_PAM
#undef VSF_BUILD_SSL

#endif /* VSF_BUILDDEFS_H */

