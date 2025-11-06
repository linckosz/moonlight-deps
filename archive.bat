mkdir output
mkdir output\include
mkdir output\include\AMF
mkdir output\lib

xcopy /e Vulkan-Headers\include output\include
xcopy /e AMF\public\include output\include\AMF

mkdir output\include\%1
mkdir output\lib\%1

xcopy /e build\FFmpeg\build_%1\include output\include\%1

copy build\dav1d\install_%1\bin\* output\lib\%1
copy build\dav1d\install_%1\lib\*.lib output\lib\%1
copy build\FFmpeg\build_%1\bin\* output\lib\%1

7z a windows-%1.zip .\output\*