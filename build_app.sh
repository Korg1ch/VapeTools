#!/bin/bash

# Скрипт для сборки VapeTools только для Android
# Для запуска: sh build_app.sh

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Скрипт сборки VapeTools для Android ===${NC}"
echo -e "${YELLOW}Начало работы: $(date)${NC}\n"

# Проверка наличия Flutter
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}Flutter не установлен. Установите Flutter перед запуском скрипта.${NC}"
    exit 1
fi

# Проверка наличия Android SDK
if [[ -z "${ANDROID_HOME}" && -z "${ANDROID_SDK_ROOT}" ]]; then
    echo -e "${YELLOW}Переменная ANDROID_HOME или ANDROID_SDK_ROOT не установлена.${NC}"
    echo -e "${YELLOW}Проверьте настройки Android SDK.${NC}"
    # Пытаемся угадать расположение SDK
    if [[ -d "${HOME}/Library/Android/sdk" ]]; then
        export ANDROID_SDK_ROOT="${HOME}/Library/Android/sdk"
        echo -e "${GREEN}Найден Android SDK в ${ANDROID_SDK_ROOT}${NC}"
    else
        echo -e "${RED}Android SDK не найден. Сборка Android-приложения может не работать.${NC}"
    fi
fi

# Функция для проверки ошибок
check_error() {
    if [ $? -ne 0 ]; then
        echo -e "${RED}Ошибка: $1${NC}"
        exit 1
    fi
}

# Создаем директорию для готовых сборок
BUILD_DIR="build/android_releases"
mkdir -p $BUILD_DIR
check_error "Не удалось создать директорию для сборок"

# Очистка проекта
echo -e "${BLUE}Очистка проекта...${NC}"
flutter clean
check_error "Не удалось очистить проект"

# Получение зависимостей
echo -e "${BLUE}Получение зависимостей...${NC}"
flutter pub get
check_error "Не удалось получить зависимости"

# Сборка для Android
echo -e "\n${BLUE}=== Сборка для Android ===${NC}"

# Список архитектур для сборки
ARCHITECTURES=("armeabi-v7a" "arm64-v8a" "x86_64")

# Сборка APK с разделением по ABI
echo -e "${YELLOW}Сборка APK с разделением по архитектурам...${NC}"
flutter build apk --split-per-abi
check_error "Не удалось собрать APK с разделением по архитектурам"

# Копируем файлы в директорию сборок
echo -e "${GREEN}Копирование APK файлов в $BUILD_DIR...${NC}"
for ARCH in "${ARCHITECTURES[@]}"; do
    cp build/app/outputs/flutter-apk/app-$ARCH-release.apk $BUILD_DIR/VapeTools-$ARCH.apk
    echo -e "✅ Создан файл $BUILD_DIR/VapeTools-$ARCH.apk"
done

# Сборка универсального APK
echo -e "${YELLOW}Сборка универсального APK...${NC}"
flutter build apk
check_error "Не удалось собрать универсальный APK"
cp build/app/outputs/flutter-apk/app-release.apk $BUILD_DIR/VapeTools-universal.apk
echo -e "✅ Создан файл $BUILD_DIR/VapeTools-universal.apk"

# Сборка Android App Bundle (AAB) для Google Play
echo -e "${YELLOW}Сборка Android App Bundle для Google Play...${NC}"
flutter build appbundle
check_error "Не удалось собрать Android App Bundle"
cp build/app/outputs/bundle/release/app-release.aab $BUILD_DIR/VapeTools.aab
echo -e "✅ Создан файл $BUILD_DIR/VapeTools.aab"

# Получение информации о размерах файлов
echo -e "\n${BLUE}=== Информация о размерах файлов ===${NC}"
for FILE in $BUILD_DIR/*; do
    SIZE=$(du -h "$FILE" | cut -f1)
    echo -e "📦 $(basename "$FILE"): ${GREEN}$SIZE${NC}"
done

# Создаем файл с информацией о сборке
echo -e "\n${BLUE}=== Создание информационного файла ===${NC}"
echo -e "VapeTools - Информация о сборке для Android\n" > $BUILD_DIR/BUILD_INFO.txt
echo -e "Дата сборки: $(date)\n" >> $BUILD_DIR/BUILD_INFO.txt
echo -e "Версия Flutter: $(flutter --version | grep Flutter | head -1)\n" >> $BUILD_DIR/BUILD_INFO.txt
echo -e "Содержимое сборки:" >> $BUILD_DIR/BUILD_INFO.txt
ls -la $BUILD_DIR >> $BUILD_DIR/BUILD_INFO.txt

echo -e "\n${GREEN}=== Сборка VapeTools для Android завершена! ===${NC}"
echo -e "${GREEN}Все файлы сборки находятся в директории: ${BLUE}$BUILD_DIR${NC}"
echo -e "${YELLOW}Содержимое директории:${NC}"
ls -la $BUILD_DIR | grep -v "BUILD_INFO.txt"
echo -e "\n${BLUE}Завершено: $(date)${NC}"
