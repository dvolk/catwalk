#include <vector>
#include <algorithm>
#include <iostream>
#include <chrono>
#include <unordered_set>

std::vector<int>::iterator sym_diff1(std::vector<int>::iterator first1, std::vector<int>::iterator last1,
				    std::vector<int>::iterator first2, std::vector<int>::iterator last2,
				    std::vector<int>::iterator result)
{
  while (first1 != last1 && first2 != last2)
    if (*first1 < *first2)
      {
	*result = *first1;
	++first1;
	++result;
      }
    else if (*first2 < *first1)
      {
	*result = *first2;
	++first2;
	++result;
      }
    else
      {
	++first1;
	++first2;
      }
  return std::copy(first2, last2,
		   std::copy(first1, last1, result));
}

std::vector<int> buf0(100000);
std::vector<int> buf1(100000);
std::vector<int> buf2(100000);
std::vector<int> buf3(100000);
std::vector<int> buf4(100000);
std::vector<int> buf5(100000);
std::vector<int> buf6(100000);
std::vector<int> buf7(100000);
std::vector<int> buf8(100000);
std::vector<int> buf9(100000);
std::vector<int> buf10(100000);
int sum_symdiff1(std::vector<int> &v0, std::vector<int> &v1,
		std::vector<int> &v2, std::vector<int> &v3,
		std::vector<int> &v4, std::vector<int> &v5,
		std::vector<int> &v6, std::vector<int> &v7,
		std::vector<int> &v8, std::vector<int> &v9,
		std::vector<int> &v10, std::vector<int> &v11)
{
  std::vector<int>::iterator it0;
  std::vector<int>::iterator it1;
  std::vector<int>::iterator it2;
  std::vector<int>::iterator it3;
  std::vector<int>::iterator it4;
  std::vector<int>::iterator it5;
  std::vector<int>::iterator it;

  //auto start = std::chrono::high_resolution_clock::now();
  it = merge(v0.begin(), v0.end(), v1.begin(), v1.end(), buf0.begin());
  buf0.resize(v0.size() + v1.size());
  it = merge(v2.begin(), v2.end(), v3.begin(), v3.end(), buf1.begin());
  buf1.resize(v2.size() + v3.size());
  it = merge(v4.begin(), v4.end(), v5.begin(), v5.end(), buf2.begin());
  buf2.resize(v4.size() + v5.size());
  it = merge(v6.begin(), v6.end(), v7.begin(), v7.end(), buf3.begin());
  buf3.resize(v6.size() + v7.size());
  it = merge(v8.begin(), v8.end(), v9.begin(), v9.end(), buf4.begin());
  buf4.resize(v8.size() + v9.size());
  it = merge(v10.begin(), v10.end(), v11.begin(), v11.end(), buf5.begin());
  buf5.resize(v10.size() + v10.size());

  it = merge(buf0.begin(), buf0.end(), buf1.begin(), buf1.end(), buf6.begin());
  buf6.resize(buf0.size() + buf1.size());
  it = merge(buf2.begin(), buf2.end(), buf3.begin(), buf3.end(), buf7.begin());
  buf7.resize(buf2.size() + buf3.size());
  it = merge(buf4.begin(), buf4.end(), buf5.begin(), buf5.end(), buf8.begin());
  buf8.resize(buf4.size() + buf5.size());

  it = merge(buf6.begin(), buf6.end(), buf7.begin(), buf7.end(), buf9.begin());
  buf9.resize(buf6.size() + buf7.size());

  it = sym_diff1(buf8.begin(), buf8.end(), buf9.begin(), buf9.end(), buf10.begin());
  buf10.resize(it - buf10.begin());

  std::cout << "buf10 before unique ";
  for(auto&& x : buf10) {
    std::cout << x << " ";
  }
  std::cout << std::endl;

  it = std::unique(buf10.begin(), buf10.end());
  buf10.resize(it - buf10.begin());

  std::cout << "buf10 after unique ";
  for(auto&& x : buf10) {
    std::cout << x << " ";
  }
  std::cout << std::endl;

  //auto finish = std::chrono::high_resolution_clock::now();
  //std::cout << std::chrono::duration_cast<std::chrono::nanoseconds>(finish-start).count() << "ns\n";

  //start = std::chrono::high_resolution_clock::now();
  //std::sort(buf.begin(), buf.end());

  //finish = std::chrono::high_resolution_clock::now();
  //std::cout << std::chrono::duration_cast<std::chrono::nanoseconds>(finish-start).count() << "ns\n";

  //start = std::chrono::high_resolution_clock::now();

  //it5 = std::unique(buf.begin(), buf.end());

  //finish = std::chrono::high_resolution_clock::now();
  //std::cout << std::chrono::duration_cast<std::chrono::nanoseconds>(finish-start).count() << "ns\n";

  return it - buf10.begin();
}

std::unordered_set<int> s;
void symdiff2(std::vector<int>::iterator first1, std::vector<int>::iterator last1,
	      std::vector<int>::iterator first2, std::vector<int>::iterator last2)
{
  while (first1 != last1 && first2 != last2)
    if (*first1 < *first2)
      {
	s.insert(*first1);
	++first1;
      }
    else if (*first2 < *first1)
      {
	s.insert(*first2);
	++first2;
      }
    else
      {
	++first1;
	++first2;
      }
  for(std::vector<int>::iterator it = first1; it != last1; ++it) 
    s.insert(*it);
  for(std::vector<int>::iterator it = first2; it != last2; ++it) 
    s.insert(*it);
}

int sum_symdiff2(std::vector<int> &v0, std::vector<int> &v1,
		 std::vector<int> &v2, std::vector<int> &v3,
		 std::vector<int> &v4, std::vector<int> &v5,
		 std::vector<int> &v6, std::vector<int> &v7,
		 std::vector<int> &v8, std::vector<int> &v9,
		 std::vector<int> &v10, std::vector<int> &v11)
{
  s.clear();
  symdiff2(v0.begin(), v0.end(), v1.begin(), v1.end());
  symdiff2(v2.begin(), v2.end(), v3.begin(), v3.end());
  symdiff2(v4.begin(), v4.end(), v5.begin(), v5.end());
  symdiff2(v6.begin(), v6.end(), v7.begin(), v7.end());
  symdiff2(v8.begin(), v8.end(), v9.begin(), v9.end());
  symdiff2(v10.begin(), v10.end(), v11.begin(), v11.end());

  return s.size();
}

int main() {

  std::cout << "hello" << std::endl;
  std::vector<int> xs0, xs1, xs2, xs3, xs4, xs5, xs6, xs7, xs8, xs9, xs10, xs11;

  for (int x = 0; x < 100000; x++) {
    xs0.push_back(x);
    xs1.push_back(x + 10);
    xs2.push_back(x + 100000);
    xs3.push_back(x - 100000);
    xs4.push_back(x);
    xs5.push_back(x * 2);
    xs6.push_back(x * 3);
    xs7.push_back(x * 4);
    xs8.push_back(x);
    xs9.push_back(x + 1000);
    xs10.push_back(x - 1000);
    xs11.push_back(x);
  }

  auto start = std::chrono::high_resolution_clock::now();
  for (int i = 0; i < 500; i++) {
    std::cout << sum_symdiff2(xs0, xs1, xs2, xs3, xs4, xs5, xs6, xs7, xs8, xs9, xs10, xs11) << std::endl;
  }
  auto finish = std::chrono::high_resolution_clock::now();
  std::cout << std::chrono::duration_cast<std::chrono::nanoseconds>(finish-start).count() << "ns\n";

  return 0;
}
