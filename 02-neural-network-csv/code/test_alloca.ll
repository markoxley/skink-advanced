; ModuleID = 'Skink'
source_filename = "Skink"

declare i32 @printf(i8*, ...)

@str.newline = private constant [2 x i8] c"\0A\00"

declare i8* @malloc(i64)
declare void @free(i8*)
declare i8* @Skink_rc_alloc(i64)
declare i8* @Skink_rc_retain(i8*)
declare void @Skink_rc_release(i8*)
declare i64 @strlen(i8*)
declare i8* @strcpy(i8*, i8*)
declare i8* @strcat(i8*, i8*)
declare i32 @strcmp(i8*, i8*)
declare void @exit(i32)
declare i32 @usleep(i32)
declare i8* @calloc(i64, i64)
declare i8* @strncpy(i8*, i8*, i64)
declare double @pow(double, double)
declare double @sin(double)
declare double @cos(double)
declare double @tan(double)
declare double @sqrt(double)

declare i8* @Skink_tensor_ones(i32, i32)
declare i8* @Skink_tensor_zeros(i32, i32)
declare i8* @Skink_tensor_matmul(i8*, i8*)
declare double @Skink_tensor_get(i8*, i32, i32)
declare void @Skink_tensor_free(i8*)
declare i8* @Skink_tensor_transpose(i8*)
declare double @Skink_tensor_det(i8*)
declare i8* @Skink_tensor_inv(i8*)
declare double @Skink_math_diff(double (double)*, double)
declare double @Skink_math_integrate(double (double)*, double, double)
declare i8* @Skink_tensor_gradient(double (double*)*, i8*)
declare double @Skink_tensor_dot(i8*, i8*)
declare i8* @Skink_tensor_cross(i8*, i8*)
declare double @Skink_tensor_norm(i8*)
declare i8* @Skink_tensor_eigenvalues(i8*)

declare i8* @Skink_chan_make(i32, i32)
declare void @Skink_chan_send(i8*, i8*)
declare i8* @Skink_chan_recv(i8*)
declare void @Skink_chan_close(i8*)
declare i32 @Skink_chan_select(i32, i8**, i32*, i8**, i8**, i32)
declare i8* @Skink_future_make()
declare void @Skink_future_set(i8*, i8*)
declare i8* @Skink_future_get(i8*)
declare void @Skink_spawn(i8*, i8*, i8*)
declare void @Skink_free(i8*)

declare i8* @Skink_ruleset_create()
declare void @Skink_ruleset_add_rule(i8*, i8*, void (i8*)*, void (i8*)*, void (i8*)*, i32)
declare void @Skink_ruleset_start(i8*)
declare void @Skink_ruleset_stop(i8*)
declare void @Skink_ruleset_reset(i8*)
declare i32 @Skink_ruleset_is_running(i8*)
declare i8* @Skink_ruleset_loop(i8*)

%set.Int = type { i32*, i32 }
%set.Str = type { i8**, i32 }
%error = type { i8* (i8*)*, i8* }

declare i1 @reflect_get_bool(i64, i32)
declare void @reflect_set_bool(i64, i32, i1)
declare i32 @reflect_get_int(i64, i32)
declare void @reflect_set_int(i64, i32, i32)
declare i64 @reflect_get_int64(i64, i32)
declare void @reflect_set_int64(i64, i32, i64)
declare i8* @reflect_get_string(i64, i32)
declare void @reflect_set_string(i64, i32, i8*)
declare double @reflect_get_float(i64, i32)
declare void @reflect_set_float(i64, i32, double)
declare i32 @reflect_hash(i64, i8*)

@str.1 = private constant [7 x i8] c"x = %d\00"
define i32 @foo() {
entry:
  %r1 = alloca i32
  %r4 = alloca i32
  store i32 0, i32* %r1
  br label %L1
L1:
  %r2 = load i32, i32* %r1
  %r3 = icmp slt i32 %r2, 5
  br i1 %r3, label %L2, label %L4
L2:
  %r5 = load i32, i32* %r1
  %r6 = add i32 %r5, 1
  store i32 %r6, i32* %r4
  %r7 = getelementptr inbounds [7 x i8], [7 x i8]* @str.1, i64 0, i64 0
  %r8 = load i32, i32* %r4
  %r9 = call i32 (i8*, ...) @printf(i8* %r7, i32 %r8)
  %r10 = load i32, i32* %r1
  %r11 = add i32 %r10, 1
  store i32 %r11, i32* %r1
  br label %L3
L3:
  br label %L1
L4:
  ret i32 0
}

define i32 @_skink_main() {
entry:
  %r1 = call i32 @foo()
  ret i32 0
}


; Skink runtime: argc/argv globals
@skink_argc = global i32 0
@skink_argv = global i8** null

define void @_skink_runtime_set_argc(i32 %argc) {
entry:
  store i32 %argc, i32* @skink_argc
  ret void
}

define void @_skink_runtime_set_argv(i8** %argv) {
entry:
  store i8** %argv, i8*** @skink_argv
  ret void
}

define i32 @_skink_runtime_get_argc() {
entry:
  %r = load i32, i32* @skink_argc
  ret i32 %r
}

define i8** @_skink_runtime_get_argv() {
entry:
  %r = load i8**, i8*** @skink_argv
  ret i8** %r
}

define i32 @main(i32 %argc, i8** %argv) {
entry:
  call void @_skink_runtime_set_argc(i32 %argc)
  call void @_skink_runtime_set_argv(i8** %argv)
  %r = call i32 @_skink_main()
  ret i32 %r
}
