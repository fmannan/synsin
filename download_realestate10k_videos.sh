DATA_ROOT=$1

if [[ ${DATA_ROOT} = "" ]]; then
  echo "Usage: ${0} <path-to-realestate10k>"
  exit 0
fi

mkdir -p ${DATA_ROOT}/train_vid
find ${DATA_ROOT}/train -name "*.txt" -exec head -n 1 {} \; > ${DATA_ROOT}/train_vid/train_vid.txt

mkdir -p ${DATA_ROOT}/test_vid
find ${DATA_ROOT}/test -name "*.txt" -exec head -n 1 {} \; > ${DATA_ROOT}/test_vid/test_vid.txt

cd ${DATA_ROOT}/train_vid
youtube-dl -i --batch-file train_vid.txt --id

cd ${DATA_ROOT}/test_vid
youtube-dl -i --batch-file test_vid.txt --id