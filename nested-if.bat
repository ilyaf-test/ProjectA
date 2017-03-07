if defined foo if defined bar (
    echo "entered this far 1"

    set errorlevel=1
    if %errorlevel% NEQ 0 (
        echo "entered this far 2"
    )

    if defined bar (
        echo "entered this far 3"
    )

    IF %ERRORLEVEL% NEQ 0 (
        EXIT 1
    )

)
